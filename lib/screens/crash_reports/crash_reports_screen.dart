import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/crash_report_model.dart';
import 'package:farmers_admin/services/admin_crash_reports_api_service.dart';
import 'package:farmers_admin/widgets/compact_action_tile.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

class CrashReportsScreen extends StatefulWidget {
  const CrashReportsScreen({super.key});

  @override
  State<CrashReportsScreen> createState() => _CrashReportsScreenState();
}

class _CrashReportsScreenState extends State<CrashReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveScaffold(
      title: 'Farmers Admin',
      sideMenu: SideMenu(),
      content: CrashReportsContent(),
    );
  }
}

class CrashReportsContent extends StatefulWidget {
  const CrashReportsContent({super.key});

  @override
  State<CrashReportsContent> createState() => _CrashReportsContentState();
}

class _CrashReportsContentState extends State<CrashReportsContent> {
  List<CrashReportModel> _crashes = [];
  bool _loading = true;
  String _searchQuery = '';
  String _appliedSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _rowsPerPage = 10;
  final double rowHeight = 40;
  final double headerHeight = 50;
  @override
  void initState() {
    super.initState();
    _loadCrashes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCrashes() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = context.read<AdminCrashReportsApiService>();
      final list = await service.getCrashReports(limit: 200);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _crashes = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _crashes = [];
          _loading = false;
        });
      }
    }
  }

  bool _matchesFilters(CrashReportModel c) {
    if (_appliedSearchQuery.isEmpty) return true;
    final q = _appliedSearchQuery.toLowerCase().trim();
    return c.message.toLowerCase().contains(q) ||
        c.platform.toLowerCase().contains(q) ||
        c.userId.toLowerCase().contains(q) ||
        c.appVersion.toLowerCase().contains(q);
  }

  void _applyFilters() {
    setState(() {
      _appliedSearchQuery = _searchQuery;
      _currentPage = 1;
    });
  }

  int _safeCurrentPage(int totalRows) {
    if (totalRows <= 0) return 1;
    final totalPages = (totalRows / _rowsPerPage).ceil().clamp(1, 999999);
    return _currentPage.clamp(1, totalPages);
  }

  void _showStackDialog(CrashReportModel crash) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 560),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Crash details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                crash.message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Platform: ${crash.platform.isEmpty ? "—" : crash.platform}  |  '
                'Version: ${crash.versionLabel}  |  '
                'Fatal: ${crash.fatal ? "Yes" : "No"}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              if (crash.userId.isNotEmpty) ...[
                const SizedBox(height: 4),
                SelectableText(
                  'User ID: ${crash.userId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Stack trace',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      crash.stack.isEmpty ? '(no stack)' : crash.stack,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDeleteDialog(
      context: context,
      title: 'Delete crash report',
      message: 'Are you sure you want to delete this crash report?',
      onConfirm: () => _deleteCrash(id),
      confirmText: 'Yes, Delete',
      cancelText: 'Cancel',
    );
  }

  Future<void> _deleteCrash(int id) async {
    try {
      await context.read<AdminCrashReportsApiService>().deleteCrashReport(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crash report deleted'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCrashes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<PlutoColumn> _columns(bool isMobile) {
    return [
      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Device',
        field: 'deviceName',
        type: PlutoColumnType.text(),
        width: isMobile ? 120 : 150,
        enableEditingMode: false,
        renderer: (ctx) {
          final v = ctx.cell.value?.toString() ?? '';
          return Tooltip(
            message: v.isEmpty ? '—' : v,
            child: Text(
              v.isEmpty ? '—' : v,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'OS',
        field: 'platform',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 110,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'App version',
        field: 'version',
        type: PlutoColumnType.text(),
        width: 130,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Fatal',
        field: 'fatal',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
        renderer: (ctx) {
          final fatal = ctx.cell.value == true || ctx.cell.value == 'Yes';
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: fatal ? Colors.red.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fatal ? 'Yes' : 'No',
                style: TextStyle(
                  fontSize: 11,
                  color: fatal ? Colors.red : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      // PlutoColumn(
      //   title: 'User ID',
      //   field: 'userId',
      //   type: PlutoColumnType.text(),
      //   width: isMobile ? 120 : 140,
      //   enableEditingMode: false,
      // ),
      PlutoColumn(
        title: 'Message',
        field: 'message',
        type: PlutoColumnType.text(),
        width: isMobile ? 180 : 320,
        enableEditingMode: false,
        renderer: (ctx) {
          final v = ctx.cell.value?.toString() ?? '';
          return Tooltip(
            message: v,
            child: Text(
              v,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        width: isMobile ? 120 : 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        enableSorting: false,
        renderer: (ctx) {
          final data = ctx.row.cells['crashData']?.value;
          if (data is! CrashReportModel) return const SizedBox.shrink();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CompactActionTile(
                backgroundColor: Colors.green.shade50,
                iconColor: Colors.green,
                icon: Icons.visibility,
                tooltip: 'View stack',
                onPressed: () => _showStackDialog(data),
              ),
              const SizedBox(width: 8),
              CompactActionTile(
                backgroundColor: Colors.red.shade50,
                iconColor: Colors.red,
                icon: Icons.delete,
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(data.id),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'crashData',
        field: 'crashData',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final filtered = _crashes.where(_matchesFilters).toList();
    final totalRows = filtered.length;
    final totalPages = totalRows == 0 ? 1 : (totalRows / _rowsPerPage).ceil();
    final safeCurrentPage = _safeCurrentPage(totalRows);
    final start = (safeCurrentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, totalRows);
    final pageItems = totalRows == 0
        ? <CrashReportModel>[]
        : filtered.sublist(start, end);
    final double gridHeight = (pageItems.length * rowHeight) + headerHeight;
    final rows = pageItems.asMap().entries.map((e) {
      final i = start + e.key + 1;
      final c = e.value;
      return PlutoRow(
        cells: {
          'no': PlutoCell(value: i),
          'date': PlutoCell(value: c.formattedDate),
          'platform': PlutoCell(value: c.platform.isEmpty ? '—' : c.platform),
          'version': PlutoCell(value: c.versionLabel),
          'fatal': PlutoCell(value: c.fatal),
          // 'userId': PlutoCell(value: c.shortUserId),
          'message': PlutoCell(value: c.shortMessage),
          'deviceName': PlutoCell(
            value: c.deviceName.isEmpty ? '—' : c.deviceName,
          ),
          'actions': PlutoCell(value: ''),
          'crashData': PlutoCell(value: c),
        },
      );
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 30,
                  vertical: isMobile ? 12 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crash Reports',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dashboard / Crash Reports',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loadCrashes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(_loading ? 'Loading...' : 'Reload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Search message, platform, user ID…',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                              ),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              onSubmitted: (_) => _applyFilters(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: _applyFilters,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _appliedSearchQuery = '';
                                        _currentPage = 1;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: const Text("CLEAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      Container(
                        height: 300.0,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(
                            child: LoadingOverlay(
                              text: 'Loading...',
                              showBackdrop: false,
                            ),
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      SizedBox(
                        height: 250,
                        child: Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'images/image_farm_nothing_remains.png',
                                height: 150,
                              ),
                              Text(
                                _crashes.isEmpty
                                    ? 'No crash reports yet'
                                    : 'No crashes match your search',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: gridHeight,
                        child: PlutoGrid(
                          key: ValueKey(
                            '$_currentPage-$_rowsPerPage-$_appliedSearchQuery',
                          ),
                          columns: _columns(isMobile),
                          rows: rows,
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
                              cellTextStyle: const TextStyle(fontSize: 12),
                              enableColumnBorderHorizontal: true,
                              enableCellBorderHorizontal: true,
                              enableColumnBorderVertical: true,
                              enableRowColorAnimation: false,
                              oddRowColor: Colors.white,
                              evenRowColor: Colors.grey.shade50,
                            ),
                          ),
                          onLoaded: (_) {},
                        ),
                      ),
                    if (!_loading && filtered.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 8,
                          horizontal: isMobile ? 4 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
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
                                        onPressed: safeCurrentPage > 1
                                            ? () => setState(
                                                () => _currentPage =
                                                    safeCurrentPage - 1,
                                              )
                                            : null,
                                      ),
                                      Text(
                                        '$safeCurrentPage / $totalPages',
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
                                        onPressed: safeCurrentPage < totalPages
                                            ? () => setState(
                                                () => _currentPage =
                                                    safeCurrentPage + 1,
                                              )
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
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
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
                                                      style: const TextStyle(
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
                                        "/ Page",
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
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    onPressed: safeCurrentPage > 1
                                        ? () => setState(
                                            () => _currentPage =
                                                safeCurrentPage - 1,
                                          )
                                        : null,
                                  ),
                                  ...List.generate(
                                    totalPages > 7 ? 7 : totalPages,
                                    (index) {
                                      int pageNum;
                                      if (totalPages <= 7) {
                                        pageNum = index + 1;
                                      } else if (safeCurrentPage <= 4) {
                                        pageNum = index + 1;
                                      } else if (safeCurrentPage >=
                                          totalPages - 3) {
                                        pageNum = totalPages - 6 + index;
                                      } else {
                                        pageNum = safeCurrentPage - 3 + index;
                                      }

                                      final isActive =
                                          pageNum == safeCurrentPage;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _currentPage = pageNum,
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
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
                                              color: isActive
                                                  ? const Color(0xFF4CAF50)
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
                                    onPressed: safeCurrentPage < totalPages
                                        ? () => setState(
                                            () => _currentPage =
                                                safeCurrentPage + 1,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
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
                                                      style: const TextStyle(
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
