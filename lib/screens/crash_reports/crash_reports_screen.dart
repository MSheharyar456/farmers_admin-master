import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/crash_report_model.dart';
import 'package:farmers_admin/services/admin_crash_reports_api_service.dart';
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

  void _showStackDialog(CrashReportModel crash) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete crash report'),
        content: const Text(
          'Remove this crash report from the server? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteCrash(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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
        width: 50,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        width: isMobile ? 110 : 130,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Platform',
        field: 'platform',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: 'App version',
          field: 'version',
          type: PlutoColumnType.text(),
          width: 100,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: 'Fatal',
        field: 'fatal',
        type: PlutoColumnType.text(),
        width: 60,
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
      if (!isMobile)
        PlutoColumn(
          title: 'User ID',
          field: 'userId',
          type: PlutoColumnType.text(),
          width: 100,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: 'Message',
        field: 'message',
        type: PlutoColumnType.text(),
        width: isMobile ? 140 : 220,
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
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 90,
        enableEditingMode: false,
        enableSorting: false,
        renderer: (ctx) {
          final data = ctx.row.cells['crashData']?.value;
          if (data is! CrashReportModel) return const SizedBox.shrink();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.visibility, size: 16, color: Colors.green),
                tooltip: 'View stack',
                onPressed: () => _showStackDialog(data),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
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
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, totalRows);
    final pageItems = totalRows == 0 ? <CrashReportModel>[] : filtered.sublist(start, end);

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
          'userId': PlutoCell(value: c.shortUserId),
          'message': PlutoCell(value: c.shortMessage),
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
                    Text(
                      'Crash Reports',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dashboard / Crash Reports',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
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
                                  borderSide: BorderSide(color: Colors.green, width: 1),
                                ),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                              onSubmitted: (_) => _applyFilters(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'images/ic_farm_filter.svg',
                                height: 12,
                                width: 12,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'FILTER',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadCrashes,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Text(
                            _crashes.isEmpty
                                ? 'No crash reports yet'
                                : 'No crashes match your search',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 400,
                        child: PlutoGrid(
                          columns: _columns(isMobile),
                          rows: rows,
                          configuration: PlutoGridConfiguration(
                            style: PlutoGridStyleConfig(
                              gridBorderColor: Colors.grey.shade300,
                              borderColor: Colors.grey.shade300,
                              activatedBorderColor: Colors.green,
                              rowHeight: 40,
                              columnHeight: 44,
                            ),
                          ),
                          onLoaded: (_) {},
                        ),
                      ),
                    if (!_loading && filtered.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('Page $_currentPage of $totalPages ($totalRows total)'),
                          IconButton(
                            onPressed: _currentPage < totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
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
