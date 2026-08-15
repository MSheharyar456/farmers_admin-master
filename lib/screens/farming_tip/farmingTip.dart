import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/farming_tip_model.dart';
import 'package:farmers_admin/screens/farming_tip/add_farm_tip.dart';
import 'package:farmers_admin/screens/farming_tip/edit_farm_tip.dart';
import 'package:farmers_admin/services/farming_tip_api_service.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:farmers_admin/services/permission_helper.dart';
import 'package:provider/provider.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';

class FarmingTipManagementScreen extends StatefulWidget {
  const FarmingTipManagementScreen({super.key});

  @override
  State<FarmingTipManagementScreen> createState() =>
      _FarmingTipManagementScreenState();
}

class _FarmingTipManagementScreenState
    extends State<FarmingTipManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const FarmingContent(),
    );
  }
}

class FarmingContent extends StatefulWidget {
  const FarmingContent({super.key});

  @override
  State<FarmingContent> createState() => _FarmingContentState();
}

class _FarmingContentState extends State<FarmingContent> {
  late PlutoGridStateManager stateManager;
  List<FarmingTip> _tips = [];
  bool _isGridLoaded = false;
  bool _isLoading = true;
  final double rowHeight = 40;
  final double headerHeight = 50;

  // Permission states
  bool _canEdit = true;
  bool _canDelete = true;

  String _searchQuery = '';
  String _appliedSearchQuery = '';
  late TextEditingController _searchController;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  List<FarmingTip> get _filteredTips => _tips.where(_matchesFilters).toList();
  int get totalPages => (_filteredTips.length / _rowsPerPage).ceil();

  List<FarmingTip> get _paginatedTips {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredTips.sublist(
      startIndex,
      endIndex > _filteredTips.length ? _filteredTips.length : endIndex,
    );
  }

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: '#',
        field: 'numbering',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 60,
        minWidth: 40,
      ),
      PlutoColumn(
        title: 'Tip ID',
        field: 'id',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'English Tip',
        field: 'tip_english',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 250,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'Arabic Tip',
        field: 'tip_arabic',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 250,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'German Tip',
        field: 'tip_german',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 250,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'Turkish Tip',
        field: 'tip_turkish',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 250,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 125,
        minWidth: 125,
        renderer: (rendererContext) {
          final tipId = rendererContext.row.cells['id']!.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_canEdit)
                Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_edit.svg',
                      width: 14,
                      height: 14,
                      color: Colors.blue,
                    ),
                    tooltip: 'Edit Tip',
                    splashRadius: 20,
                    onPressed: () {
                      try {
                        final tip = _tips.firstWhere((t) => t.tipId == tipId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditFarmingTipScreen(tip: tip),
                          ),
                        ).then((_) => _loadTips());
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: Could not find tip with ID $tipId',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              if (_canEdit && _canDelete) const SizedBox(width: 8),
              if (_canDelete)
                Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_trash.svg',
                      width: 14,
                      height: 14,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete Tip',
                    splashRadius: 20,
                    onPressed: () async {
                      await showDeleteDialog(
                        context: context,
                        title: "Delete Farming Tip",
                        message:
                            "Are you sure you want to clear this farming tip?",
                        onConfirm: () async {
                          try {
                            final service = context
                                .read<FarmingTipApiService>();
                            await service.updateFarmingTip(
                              farmingTipEnglish: '',
                              farmingTipArabic: '',
                              farmingTipGerman: '',
                              farmingTipTurkish: '',
                            );
                            if (mounted) _loadTips();
                          } catch (_) {}
                        },
                      );
                    },
                  ),
                ),
              if (!_canEdit && !_canDelete)
                const Text(
                  'No actions',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
            ],
          );
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadPermissions();
    _loadTips();
  }

  Future<void> _loadTips() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final service = context.read<FarmingTipApiService>();
      final tip = await service.getFarmingTip();
      if (mounted) {
        setState(() {
          _tips = [tip];
          _isLoading = false;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tips = [];
          _isLoading = false;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    }
  }

  Future<void> _loadPermissions() async {
    final canEdit = await PermissionHelper.canEdit();
    final canDelete = await PermissionHelper.canDelete();
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
        _canDelete = canDelete;
      });
    }
  }

  bool _matchesFilters(FarmingTip tip) {
    if (_appliedSearchQuery.isNotEmpty) {
      final english = tip.farmingTipEnglish?.toLowerCase() ?? '';
      final arabic = tip.farmingTipArabic?.toLowerCase() ?? '';
      final german = tip.farmingTipGerman?.toLowerCase() ?? '';
      final turkish = tip.farmingTipTurkish?.toLowerCase() ?? '';

      if (!english.contains(_appliedSearchQuery) &&
          !arabic.contains(_appliedSearchQuery) &&
          !german.contains(_appliedSearchQuery) &&
          !turkish.contains(_appliedSearchQuery)) {
        return false;
      }
    }
    return true;
  }

  void _updatePlutoGridRows() {
    final newRows = <PlutoRow>[];
    int counter = 1;

    for (final tip in _paginatedTips) {
      newRows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()),
            'id': PlutoCell(value: tip.tipId ?? ''),
            'tip_english': PlutoCell(value: tip.farmingTipEnglish ?? ''),
            'tip_arabic': PlutoCell(value: tip.farmingTipArabic ?? ''),
            'tip_german': PlutoCell(value: tip.farmingTipGerman ?? ''),
            'tip_turkish': PlutoCell(value: tip.farmingTipTurkish ?? ''),
            'actions': PlutoCell(value: ''),
          },
        ),
      );
      counter++;
    }

    stateManager.removeAllRows();
    if (newRows.isNotEmpty) stateManager.appendRows(newRows);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _appliedSearchQuery = _searchQuery.toLowerCase();
      _currentPage = 1; // Reset to first page when filters change
      if (_isGridLoaded) _updatePlutoGridRows();
    });
  }

  Widget _buildEmptyState() {
    final hasFilters = _appliedSearchQuery.isNotEmpty;

    if (hasFilters && _tips.isNotEmpty) {
      return _buildNoResultsState();
    }

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
            Image.asset('images/image_farm_nothing_remains.png', height: 150),
            const SizedBox(height: 24),
            const Text(
              "No farming tips available",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Add your first farming tip to get started",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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
            Image.asset('images/image_farm_nothing_remains.png', height: 150),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "No farming tips found matching your filters",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                  bottom: 30,
                  top: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Farming Tips',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Dashboard / Farming Tips List",
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddFarmingTipScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Add Farming Tip",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Farming Tips',
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
                                    'Dashboard / Farming Tips List',
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
                                  const SizedBox(height: 15),
                                ],
                              ),
                              // ElevatedButton.icon(
                              //   onPressed: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //           builder: (context) =>
                              //           const AddFarmingTipScreen()),
                              //     );
                              //   },
                              //   icon:
                              //   const Icon(Icons.add, color: Colors.white),
                              //   label: const Text("Add Farming Tip",
                              //       style: TextStyle(color: Colors.white)),
                              //   style: ElevatedButton.styleFrom(
                              //     backgroundColor: Colors.green,
                              //     padding: const EdgeInsets.symmetric(
                              //         horizontal: 16, vertical: 20),
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(8),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                    const SizedBox(height: 20),

                    // Filters Section
                    isMobile
                        ? Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
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
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _applyFilters,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'images/ic_farm_filter.svg',
      height: 12,
      width: 12,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
    const SizedBox(width: 4),
    const Text(
      "APPLY",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  ],
),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _applyFilters();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text("REMOVE FILTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  width: isTablet ? 200 : 300,
                                  height: 38,
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ), //  This controls the input text size
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      hintText: 'Search...',
                                      hintStyle: TextStyle(fontSize: 12),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
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
                                            vertical: 10,
                                          ),
                                    ),
                                    onChanged: (val) {
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
                                child: Row(
                                  children: [
                                    Expanded(
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
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'images/ic_farm_filter.svg',
      height: 12,
      width: 12,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
    const SizedBox(width: 4),
    const Text(
      "APPLY",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  ],
),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                            _applyFilters();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        child: const Text("CLEAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),

                    // Grid Section
                    SizedBox(
                      child: _isLoading
                          ? Container(
                              height: _isLoading
                                  ? 300
                                  : (_paginatedTips.length * rowHeight) +
                                        headerHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const LoadingOverlay(
                                text: 'Loading...',
                                showBackdrop: false,
                              ),
                            )
                          : _tips.isEmpty
                          ? _buildEmptyState()
                          : _filteredTips.isEmpty
                          ? _buildNoResultsState()
                          : Container(
                              color: Colors.white,
                              height:
                                  (_paginatedTips.length * rowHeight) +
                                  headerHeight, // Added padding
                              child: PlutoGrid(
                                columns: _getColumns(),
                                rows: [],
                                onLoaded: (event) {
                                  stateManager = event.stateManager;
                                  stateManager.setShowColumnFilter(false);
                                  setState(() => _isGridLoaded = true);
                                  if (_tips.isNotEmpty) {
                                    _updatePlutoGridRows();
                                  }
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
                    ),

                    // Pagination Footer
                    if (!_isLoading && _filteredTips.isNotEmpty)
                      Container(
                        width: double.infinity,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        onPressed: _currentPage > 1
                                            ? () {
                                                setState(() {
                                                  _currentPage--;
                                                  _updatePlutoGridRows();
                                                });
                                              }
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
                                          color: Colors.grey,
                                        ),
                                        onPressed: _currentPage < totalPages
                                            ? () {
                                                setState(() {
                                                  _currentPage++;
                                                  _updatePlutoGridRows();
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 34,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
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
                                                      style: TextStyle(
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
                                                  _updatePlutoGridRows();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "/ Page",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _currentPage > 1
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                              _updatePlutoGridRows();
                                            });
                                          }
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
                                          pageNum = totalPages - 6 + index;
                                        } else {
                                          pageNum = _currentPage - 3 + index;
                                        }
                                      }

                                      final isActive = pageNum == _currentPage;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _currentPage = pageNum;
                                            _updatePlutoGridRows();
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFFE8F5E9)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isActive
                                                  ? const Color(0xFF4CAF50)
                                                  : Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: Text(
                                            '$pageNum',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isActive
                                                  ? const Color(0xFF4CAF50)
                                                  : Colors.black87,
                                              fontWeight: FontWeight.w500,
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
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                              _updatePlutoGridRows();
                                            });
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 34,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
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
                                                      style: TextStyle(
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
                                                  _updatePlutoGridRows();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "/ Page",
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
