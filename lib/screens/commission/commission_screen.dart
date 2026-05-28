import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/commission_model.dart';
import 'package:farmers_admin/services/commission_service.dart';
import 'package:farmers_admin/utils/localization_helper.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:farmers_admin/services/permission_helper.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const CommissionContent(),
    );
  }
}

class CommissionContent extends StatefulWidget {
  const CommissionContent({super.key});

  @override
  State<CommissionContent> createState() => _CommissionContentState();
}

class _CommissionContentState extends State<CommissionContent> {
  late PlutoGridStateManager stateManager;
  String _searchQuery = '';
  String? _selectedBank;
  // Applied filter values - used for actual filtering
  String _appliedSearchQuery = '';
  String? _appliedSelectedBank;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  final double rowHeight = 40;
  final double headerHeight = 50;
  bool _isGridLoaded = false;
  bool _isInitialLoad = true;
  final List<String> _availableBanks = [];

  // Permission states
  bool _canDelete = true;

  // API Service and data
  final CommissionService _commissionService = CommissionService();
  List<CommissionModel> _allCommissions = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadCommissions();
    // Start polling every 30 seconds for new data
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadCommissions();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    if (!mounted) return;
    if (_isInitialLoad) {
      setState(() => _isLoading = true);
    }

    try {
      final commissions = await _commissionService.getAllCommissions();
      if (mounted) {
        setState(() {
          _allCommissions = commissions;
          _isLoading = false;
          _isInitialLoad = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
          _errorMessage = 'Failed to load commissions: $e';
        });
      }
    }
  }

  Future<void> _loadPermissions() async {
    final canDelete = await PermissionHelper.canDelete();
    if (mounted) {
      setState(() {
        _canDelete = canDelete;
      });
    }
  }

  // Helper method to normalize bank names consistently
  // Trims whitespace, normalizes multiple spaces to single space, converts to lowercase
  String _normalizeBankName(String bankName) {
    if (bankName.isEmpty) return '';
    return bankName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  List<PlutoColumn> _getColumns(BuildContext context, bool isMobile) {
    return [
      PlutoColumn(
        title: AppLocalizations.translate('No'),
        field: 'no',
        type: PlutoColumnType.number(),
        width: isMobile ? 50 : 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: AppLocalizations.translate('Name'),
        field: 'name',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 150,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: AppLocalizations.translate('Phone'),
          field: 'phone',
          type: PlutoColumnType.text(),
          width: 130,
          enableEditingMode: false,
          renderer: (ctx) {
            String phone = ctx.cell.value.toString();
            // Extract only digits
            String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
            // Rebuild with + at start
            String fixedPhone = digits.isNotEmpty ? '+$digits' : phone;
            // Use Directionality widget to force LTR
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                fixedPhone,
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      PlutoColumn(
        title: AppLocalizations.translate('Bank'),
        field: 'bank',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 150,
        enableEditingMode: false,
        renderer: (ctx) {
          final bank = ctx.cell.value.toString();
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              bank,
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.translate('Commission Amount'),
        field: 'commissionAmount',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 120,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: AppLocalizations.translate('Post Code'),
          field: 'postCode',
          type: PlutoColumnType.text(),
          width: 120,
          enableEditingMode: false,
        ),
      if (!isMobile)
        PlutoColumn(
          title: AppLocalizations.translate('Request Date'),
          field: 'requestDate',
          type: PlutoColumnType.text(),
          width: 150,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: AppLocalizations.translate('Actions'),
        field: 'actions',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 120,
        minWidth: 100,
        enableEditingMode: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (ctx) {
          final commissionData = ctx.row.cells['commissionData']?.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.image, size: 12, color: Colors.blue),
                  tooltip: 'View Receipt',
                  splashRadius: 20,
                  onPressed: () {
                    if (commissionData != null &&
                        commissionData is CommissionModel) {
                      _showReceiptImage(commissionData);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.visibility,
                    size: 12,
                    color: Colors.green,
                  ),
                  tooltip: 'View Details',
                  splashRadius: 20,
                  onPressed: () {
                    if (commissionData != null &&
                        commissionData is CommissionModel) {
                      _showCommissionDetails(commissionData);
                    }
                  },
                ),
              ),
              if (_canDelete) const SizedBox(width: 8),
              if (_canDelete)
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_trash.svg',
                      width: 12,
                      height: 12,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete Commission',
                    splashRadius: 20,
                    onPressed: () async {
                      if (commissionData != null &&
                          commissionData is CommissionModel) {
                        await showDeleteDialog(
                          context: context,
                          title: "Delete Commission",
                          message:
                              "Are you sure you want to delete this commission?",
                          onConfirm: () async {
                            await _commissionService.deleteCommission(
                              commissionData.itemId,
                            );
                            // Refresh the list after delete
                            await _loadCommissions();
                          },
                        );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Commission Data',
        field: 'commissionData',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
    ];
  }

  void _showReceiptImage(CommissionModel commission) {
    if (commission.receiptUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipt image available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: commission.receiptUrl,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red, size: 50),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(ctx).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommissionDetails(CommissionModel commission) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.translate('Commission Details'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                // Details
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDetailRow(AppLocalizations.translate('Name'), commission.name),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppLocalizations.translate('Phone'), AppLocalizations.fixPhoneNumber(commission.phone)),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppLocalizations.translate('Bank'), AppLocalizations.translateBank(commission.bank)),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        AppLocalizations.translate('Commission Amount'),
                        commission.commissionAmount,
                      ),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppLocalizations.translate('Post Code'), commission.postCode),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppLocalizations.translate('Request Date'), commission.formattedDate),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      if (commission.notes.isNotEmpty) ...[
                        Align(
                          alignment: AppLocalizations.isRtl ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.translate('Notes'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            commission.notes,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isRtl = AppLocalizations.isRtl;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
        children: [
          if (!isRtl)
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              textAlign: isRtl ? TextAlign.left : TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
            ),
          ),
          if (isRtl)
            SizedBox(
              width: 140,
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesFilters(CommissionModel commission) {
    // Apply search query filter - use applied search query
    if (_appliedSearchQuery.isNotEmpty) {
      final name = commission.name.toLowerCase().trim();
      final phone = commission.phone.toLowerCase().trim();
      final postCode = commission.postCode.toLowerCase().trim();
      final searchLower = _appliedSearchQuery.toLowerCase().trim();

      if (!name.contains(searchLower) &&
          !phone.contains(searchLower) &&
          !postCode.contains(searchLower)) {
        return false;
      }
    }

    // Apply bank filter - EXACT MATCH ONLY (case-insensitive) - use applied bank
    // Check if _appliedSelectedBank is not null and not empty (and not the string "null")
    if (_appliedSelectedBank != null &&
        _appliedSelectedBank!.trim().isNotEmpty &&
        _appliedSelectedBank!.toLowerCase() != 'null') {
      // Normalize both values using the same method for consistent comparison
      final normalizedSelected = _normalizeBankName(_appliedSelectedBank!);
      final normalizedCommission = _normalizeBankName(commission.bank);

      print(
        '🔍 FILTER: Selected="$_appliedSelectedBank" (norm:"$normalizedSelected") vs Commission="${commission.bank}" (norm:"$normalizedCommission") = ${normalizedCommission == normalizedSelected}',
      );

      // STRICT EXACT MATCH - must be identical after normalization
      // Return false if banks don't match exactly (case-insensitive)
      if (normalizedCommission != normalizedSelected) {
        return false;
      }
    }

    return true;
  }

  void _applyFilters() {
    setState(() {
      // Copy input values to applied filter values
      _appliedSearchQuery = _searchQuery;
      _appliedSelectedBank = _selectedBank;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 30,
                  vertical: isMobile ? 12 : 20,
                ),
                child: Column(
                  children: [
                    // Header Row
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.translate('Commission Data'),
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                AppLocalizations.translate('Dashboard / Commission Data'),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'Roboto',
                                    ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.translate('Commission Data'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      AppLocalizations.translate('Dashboard / Commission Data'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Colors.grey,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.normal,
                                            fontFamily: 'Roboto',
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 15),
                    // FILTERS - Moved outside StreamBuilder to avoid rebuilds
                    isMobile
                        ? Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      AppLocalizations.translate('Search by name, phone, or post code...'),
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: (val) {
                                  // Only update input value, don't trigger filtering
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  // Get unique banks from loaded commissions
                                  final Map<String, String> bankMap = {};
                                  for (final commission in _allCommissions) {
                                    final bankName = commission.bank
                                        .trim()
                                        .replaceAll(RegExp(r'\s+'), ' ');
                                    if (bankName.isNotEmpty) {
                                      final normalizedKey = _normalizeBankName(bankName);
                                      if (!bankMap.containsKey(normalizedKey)) {
                                        bankMap[normalizedKey] = bankName;
                                      }
                                    }
                                  }
                                  final List<String> banksList = bankMap.values.toList()..sort();

                                  // Find matching bank from banksList using case-insensitive comparison
                                  String? effectiveSelectedBank;
                                  if (_selectedBank != null &&
                                      _selectedBank!.isNotEmpty) {
                                    final normalizedSelected =
                                        _normalizeBankName(_selectedBank!);
                                    try {
                                      effectiveSelectedBank = banksList
                                          .firstWhere(
                                            (bank) =>
                                                _normalizeBankName(bank) ==
                                                normalizedSelected,
                                            orElse: () => '',
                                          );
                                      if (effectiveSelectedBank.isEmpty) {
                                        effectiveSelectedBank = null;
                                      }
                                    } catch (e) {
                                      effectiveSelectedBank = null;
                                    }
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String?>(
                                          initialValue: effectiveSelectedBank,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                          ),
                                          hint: Text(AppLocalizations.translate('Bank')),
                                          items: [
                                            DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text(AppLocalizations.translate('All Banks')),
                                            ),
                                            ...banksList.map(
                                              (bank) =>
                                                  DropdownMenuItem<String?>(
                                                    value: bank,
                                                    child: Text(bank),
                                                  ),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            // Only update input value, don't trigger filtering
                                            setState(() {
                                              _selectedBank = val;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _applyFilters,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: SvgPicture.asset(
                                          'images/ic_farm_filter.svg',
                                          height: 20,
                                          width: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 38,
                                  child: TextField(
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      hintText:
                                          'Search by name, phone, or post code...',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 0,
                                          ),
                                    ),
                                    onChanged: (val) {
                                      // Only update input value, don't trigger filtering
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 38,
                                  child: Builder(
                                    builder: (context) {
                                      // Get unique banks from loaded commissions
                                      final Set<String> banks = {};
                                      for (final commission in _allCommissions) {
                                        final bankName = commission.bank
                                            .trim()
                                            .replaceAll(RegExp(r'\s+'), ' ');
                                        if (bankName.isNotEmpty) {
                                          banks.add(bankName);
                                        }
                                      }
                                      final List<String> banksList = banks.toList()..sort();

                                      // Ensure selected bank value matches one of the items (case-insensitive)
                                      String? effectiveSelectedBank =
                                          _selectedBank?.trim().replaceAll(
                                            RegExp(r'\s+'),
                                            ' ',
                                          );
                                      if (effectiveSelectedBank != null &&
                                          effectiveSelectedBank.isNotEmpty) {
                                        // Check if exact match exists in banksList
                                        if (!banksList.contains(
                                          effectiveSelectedBank,
                                        )) {
                                          // Try to find exact match using case-insensitive comparison
                                          final match = banksList.firstWhere(
                                            (bank) =>
                                                _normalizeBankName(bank) ==
                                                _normalizeBankName(
                                                  effectiveSelectedBank!,
                                                ),
                                            orElse: () => '',
                                          );
                                          effectiveSelectedBank = match.isEmpty
                                              ? null
                                              : match;
                                        }
                                      }

                                      return DropdownButtonFormField<String?>(
                                        initialValue: effectiveSelectedBank,
                                        dropdownColor: Colors.white,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.green,
                                                  width: 1,
                                                ),
                                              ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 0,
                                              ),
                                        ),
                                        hint: Text(
                                          AppLocalizations.translate('Filter by Bank'),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        items: [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              AppLocalizations.translate('All Banks'),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          ...banksList.map(
                                            (bank) => DropdownMenuItem<String?>(
                                              value: bank,
                                              child: Text(
                                                bank,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          // Only update input value, don't trigger filtering
                                          setState(() {
                                            _selectedBank = val;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: _applyFilters,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'images/ic_farm_filter.svg',
                                        height: 12,
                                        width: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.translate('APPLY FILTERS'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                    // PlutoGrid Section
                    Builder(
                      builder: (context) {
                        // Show loading indicator on initial load
                        if (_isLoading && _isInitialLoad) {
                          return const SizedBox(
                            height: 400,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          );
                        }

                        // Show error message if any
                        if (_errorMessage != null && _allCommissions.isEmpty) {
                          return SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadCommissions,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Show empty state if no data
                        if (_allCommissions.isEmpty) {
                          return SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'images/image_farm_nothing_remains.png',
                                    height: isMobile ? 120 : 150,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppLocalizations.translate('No commission data available'),
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.translate('Commission requests will appear here'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Filter commissions based on search and bank filter
                        final List<CommissionModel> commissions = [];

                        print(
                          '🔎 FILTERING START - _appliedSelectedBank: "$_appliedSelectedBank", _appliedSearchQuery: "$_appliedSearchQuery"',
                        );

                        for (final commission in _allCommissions) {
                          try {
                            final matches = _matchesFilters(commission);
                            print('   Result: ${commission.bank} -> $matches');
                            if (matches) {
                              commissions.add(commission);
                              print('   ✅ ADDED: ${commission.bank}');
                            } else {
                              print('   ❌ REJECTED: ${commission.bank}');
                            }
                          } catch (e) {
                            print('Error filtering commission ${commission.itemId}: $e');
                          }
                        }

                        print(
                          '📊 FINAL RESULT: ${commissions.length} commissions',
                        );
                        for (var c in commissions) {
                          print('   - ${c.bank}');
                        }
                        print('═══════════════════════════════════');
                        // Sort by requestData (newest first)
                        commissions.sort(
                          (a, b) => b.requestData.compareTo(a.requestData),
                        );
                        if (commissions.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'images/image_farm_nothing_remains.png',
                                    height: 150,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppLocalizations.translate("You're all caught up!"),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppLocalizations.translate('No commission data found'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Pagination logic
                        int totalRows = commissions.length;
                        int totalPages = (totalRows / _rowsPerPage).ceil();
                        int startIndex = (_currentPage - 1) * _rowsPerPage;
                        int endIndex = startIndex + _rowsPerPage;
                        if (endIndex > totalRows) endIndex = totalRows;

                        final paginatedCommissions = commissions.sublist(
                          startIndex,
                          endIndex,
                        );

                        print(
                          '📄 PAGINATION: Showing ${paginatedCommissions.length} of ${commissions.length} (page $_currentPage)',
                        );
                        for (var c in paginatedCommissions) {
                          print('   Displaying: ${c.bank}');
                        }

                        final List<PlutoRow> rows = paginatedCommissions
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final commission = entry.value;
                              final rowNumber = startIndex + index + 1;

                              return PlutoRow(
                                cells: {
                                  'no': PlutoCell(value: rowNumber),
                                  'name': PlutoCell(value: commission.name),
                                  'phone': PlutoCell(value: commission.phone),
                                  'bank': PlutoCell(value: commission.bank),
                                  'commissionAmount': PlutoCell(
                                    value: commission.commissionAmount,
                                  ),
                                  'postCode': PlutoCell(
                                    value: commission.postCode,
                                  ),
                                  'requestDate': PlutoCell(
                                    value: commission.formattedDate,
                                  ),
                                  'actions': PlutoCell(value: ''),
                                  'commissionData': PlutoCell(
                                    value: commission,
                                  ),
                                },
                              );
                            })
                            .toList();

                        return Column(
                          children: [
                            SizedBox(
                              height: (rows.length * rowHeight) + headerHeight,
                              child: PlutoGrid(
                                key: ValueKey(
                                  'grid_${_appliedSelectedBank}_${_appliedSearchQuery}_$_currentPage',
                                ), // Force rebuild when filter changes
                                columns: _getColumns(context, isMobile),
                                rows: rows,
                                onLoaded: (event) {
                                  stateManager = event.stateManager;
                                  stateManager.setShowColumnFilter(false);
                                  setState(() => _isGridLoaded = true);
                                },
                                configuration: PlutoGridConfiguration(
                                  columnSize: const PlutoGridColumnSizeConfig(
                                    autoSizeMode: PlutoAutoSizeMode.scale,
                                  ),
                                  style: PlutoGridStyleConfig(
                                    rowHeight: 40,
                                    columnTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    cellTextStyle: const TextStyle(
                                      fontSize: 12,
                                    ),
                                    enableColumnBorderHorizontal: true,
                                    enableCellBorderHorizontal: true,
                                    enableColumnBorderVertical: true,
                                    enableRowColorAnimation: false,
                                    oddRowColor: Colors.white,
                                    evenRowColor: Colors.grey.shade50,
                                  ),
                                ),
                              ),
                            ),
                            // Pagination Footer
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 8,
                                horizontal: isMobile ? 4 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isMobile
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.arrow_back_ios_new,
                                                size: 14,
                                              ),
                                              onPressed: _currentPage > 1
                                                  ? () => setState(
                                                      () => _currentPage--,
                                                    )
                                                  : null,
                                            ),
                                            Text(
                                              '$_currentPage / $totalPages',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14,
                                              ),
                                              onPressed:
                                                  _currentPage < totalPages
                                                  ? () => setState(
                                                      () => _currentPage++,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: 34,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: Colors.white,
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  value: _rowsPerPage,
                                                  dropdownColor: Colors.white,
                                                  icon: const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 14,
                                                  ),
                                                  items: [5, 10, 20, 50]
                                                      .map(
                                                        (e) => DropdownMenuItem(
                                                          value: e,
                                                          child: Text(
                                                            '$e',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setState(() {
                                                        _rowsPerPage = val;
                                                        _currentPage = 1;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              '/ Page',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          onPressed: _currentPage > 1
                                              ? () => setState(
                                                  () => _currentPage--,
                                                )
                                              : null,
                                        ),
                                        ...List.generate(
                                          totalPages > 7 ? 7 : totalPages,
                                          (index) {
                                            int pageNum;
                                            if (totalPages <= 7) {
                                              pageNum = index + 1;
                                            } else {
                                              if (_currentPage <= 4) {
                                                pageNum = index + 1;
                                              } else if (_currentPage >=
                                                  totalPages - 3) {
                                                pageNum =
                                                    totalPages - 6 + index;
                                              } else {
                                                pageNum =
                                                    _currentPage - 3 + index;
                                              }
                                            }

                                            bool isActive =
                                                pageNum == _currentPage;

                                            return GestureDetector(
                                              onTap: () => setState(
                                                () => _currentPage = pageNum,
                                              ),
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? const Color(0xFFE8F5E9)
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: isActive
                                                        ? const Color(
                                                            0xFF4CAF50,
                                                          )
                                                        : Colors.grey.shade300,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  '$pageNum',
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? const Color(
                                                            0xFF4CAF50,
                                                          )
                                                        : Colors.black87,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          onPressed: _currentPage < totalPages
                                              ? () => setState(
                                                  () => _currentPage++,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 20),
                                        Row(
                                          children: [
                                            Container(
                                              height: 34,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                color: Colors.white,
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  value: _rowsPerPage,
                                                  icon: const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 14,
                                                  ),
                                                  items: [5, 10, 20, 50]
                                                      .map(
                                                        (e) => DropdownMenuItem(
                                                          value: e,
                                                          child: Text(
                                                            '$e',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setState(() {
                                                        _rowsPerPage = val;
                                                        _currentPage = 1;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              '/ Page',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
