import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/post_report_model.dart';
import 'package:farmers_admin/services/admin_report_posts_api_service.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';

class PostReportScreen extends StatefulWidget {
  const PostReportScreen({super.key});

  @override
  State<PostReportScreen> createState() => _PostReportScreenState();
}

class _PostReportScreenState extends State<PostReportScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const PostReportContent(),
    );
  }
}

class PostReportContent extends StatefulWidget {
  const PostReportContent({super.key});

  @override
  State<PostReportContent> createState() => _PostReportContentState();
}

class _PostReportContentState extends State<PostReportContent> {
  late PlutoGridStateManager stateManager;
  List<PostReportModel> _reports = [];
  bool _loading = true;
  String _searchQuery = '';
  String _appliedSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _rowsPerPage = 10;
  final double rowHeight = 40;
  final double headerHeight = 50;
  bool _isGridLoaded = false;

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = context.read<AdminReportPostsApiService>();
      final list = await service.getReportPosts(limit: 200);
      debugPrint('[POST_REPORT] Loaded ${list.length} reports');
      if (list.isNotEmpty) {
        debugPrint('[POST_REPORT] First report: ${list.first}');
      }
      final reports = list.map((e) {
        final id = e['id']?.toString() ?? '';
        return PostReportModel.fromMap(id, e);
      }).toList();
      reports.sort((a, b) => b.postReportDate.compareTo(a.postReportDate));
      if (mounted)
        setState(() {
          _reports = reports;
          _loading = false;
        });
    } catch (e) {
      debugPrint('[POST_REPORT] Error loading reports: $e');
      if (mounted)
        setState(() {
          _reports = [];
          _loading = false;
        });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PlutoColumn> _getColumns(BuildContext context, bool isMobile) {
    return [
      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: isMobile ? 50 : 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'User Name',
        field: 'userName',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 150,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: 'Email',
          field: 'email',
          type: PlutoColumnType.text(),
          width: 180,
          enableEditingMode: false,
          renderer: (rendererContext) {
            final value = rendererContext.cell.value?.toString() ?? '';
            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: $value'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    const Icon(Icons.copy, size: 11, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      if (!isMobile)
        PlutoColumn(
          title: 'Contact',
          field: 'contact',
          type: PlutoColumnType.text(),
          width: 130,
          enableEditingMode: false,
          renderer: (rendererContext) {
            final value = rendererContext.cell.value?.toString() ?? '';
            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: $value'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    const Icon(Icons.copy, size: 11, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      if (!isMobile)
        PlutoColumn(
          title: 'Reporter ID',
          field: 'reporterId',
          type: PlutoColumnType.text(),
          width: 150,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: 'Post ID',
        field: 'postId',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 150,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: 'Report Date',
          field: 'reportDate',
          type: PlutoColumnType.text(),
          width: 150,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: isMobile ? 80 : 100,
        minWidth: 80,
        enableEditingMode: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (ctx) {
          final reportData = ctx.row.cells['reportData']?.value;
          final reportId = ctx.row.cells['reportData']?.value?.id;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // View button
              Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.visibility,
                    size: 14,
                    color: Colors.green,
                  ),
                  tooltip: 'View Details',
                  splashRadius: 20,
                  onPressed: () {
                    if (reportData != null && reportData is PostReportModel) {
                      _showReportDetails(reportData);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                  tooltip: 'Delete Report',
                  splashRadius: 20,
                  onPressed: () {
                    if (reportId != null) {
                      _confirmDelete(reportId.toString());
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Report Data',
        field: 'reportData',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
    ];
  }

  void _showReportDetails(PostReportModel report) {
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
                    children: [
                      const Text(
                        'Post Report Details',
                        style: TextStyle(
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
                      _buildDetailRow('User Name', report.currentUsername),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow('Email', report.currentUserMail),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow('Contact', report.currentUserContact),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow('Reporter ID', report.reporterUserId),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow('Post ID', report.postId),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      _buildDetailRow('Report Date', report.formattedDate),
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),
                      if (report.postRepostAdditionalDetails.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Additional Details',
                            style: TextStyle(
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
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            report.postRepostAdditionalDetails,
                            style: const TextStyle(
                              fontSize: 12,
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
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String reportId) {
    showDeleteDialog(
      context: context,
      title: 'Delete Report',
      message: 'Are you sure you want to delete this report?',
      onConfirm: () async {
        await _deleteReport(reportId);
      },
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      final service = context.read<AdminReportPostsApiService>();
      await service.deleteReportPost(reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list
        _loadReports();
      }
    } catch (e) {
      debugPrint('[POST_REPORT] Error deleting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _matchesFilters(PostReportModel report) {
    if (_appliedSearchQuery.isNotEmpty) {
      final name = report.currentUsername.toLowerCase().trim();
      final email = report.currentUserMail.toLowerCase().trim();
      final contact = report.currentUserContact.toLowerCase().trim();
      final postId = report.postId.toLowerCase().trim();
      final reporterId = report.reporterUserId.toLowerCase().trim();
      final searchLower = _appliedSearchQuery.toLowerCase().trim();

      if (!name.contains(searchLower) &&
          !email.contains(searchLower) &&
          !contact.contains(searchLower) &&
          !postId.contains(searchLower) &&
          !reporterId.contains(searchLower)) {
        return false;
      }
    }

    return true;
  }

  void _applyFilters() {
    setState(() {
      _appliedSearchQuery = _searchQuery;
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
                                'Post Report Data',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Dashboard / Post Report Data',
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
                                      'Post Report Data',
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
                                      'Dashboard / Post Report Data',
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
                    // FILTERS
                    isMobile
                        ? Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by name, email, post ID, or reporter ID...',
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
                                onSubmitted: (val) {
                                  _applyFilters();
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
                                          horizontal: 16,
                                          vertical: 12,
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
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'APPLY',
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
                                          _appliedSearchQuery = '';
                                          _currentPage = 1;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: const Text(
                                        'CLEAR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                                    controller: _searchController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText:
                                          'Search by name, email, post ID, or reporter ID...',
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
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                    onSubmitted: (val) {
                                      _applyFilters();
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
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'APPLY',
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
                                            _appliedSearchQuery = '';
                                            _currentPage = 1;
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
                                        child: const Text(
                                          'CLEAR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                    // PlutoGrid Section
                    Builder(
                      builder: (context) {
                        final reports = _reports
                            .where(_matchesFilters)
                            .toList();
                        reports.sort(
                          (a, b) =>
                              b.postReportDate.compareTo(a.postReportDate),
                        );

                        if (_loading) {
                          return Container(
                            height: _loading
                                ? 300
                                : (reports.length * rowHeight) + headerHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const LoadingOverlay(
                              text: 'Loading...',
                              showBackdrop: false,
                            ),
                          );
                        }
                        if (reports.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            height: 400,
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'images/image_farm_nothing_remains.png',
                                  height: 150,
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  _reports.isEmpty
                                      ? "No post report data available"
                                      : "You're all caught up!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _reports.isEmpty
                                      ? "Post reports will appear here"
                                      : "No post report data found matching your filters.",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        int totalRows = reports.length;
                        int totalPages = (totalRows / _rowsPerPage).ceil();
                        int startIndex = (_currentPage - 1) * _rowsPerPage;
                        int endIndex = startIndex + _rowsPerPage;
                        if (endIndex > totalRows) endIndex = totalRows;
                        final paginatedReports = reports.sublist(
                          startIndex,
                          endIndex,
                        );

                        final List<PlutoRow> rows = paginatedReports
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final report = entry.value;
                              final rowNumber = startIndex + index + 1;

                              return PlutoRow(
                                cells: {
                                  'no': PlutoCell(value: rowNumber),
                                  'userName': PlutoCell(
                                    value: report.currentUsername,
                                  ),
                                  'email': PlutoCell(
                                    value: report.currentUserMail,
                                  ),
                                  'contact': PlutoCell(
                                    value: report.currentUserContact,
                                  ),
                                  'reporterId': PlutoCell(
                                    value: report.reporterUserId,
                                  ),
                                  'postId': PlutoCell(value: report.postId),
                                  'reportDate': PlutoCell(
                                    value: report.formattedDate,
                                  ),
                                  'actions': PlutoCell(value: ''),
                                  'reportData': PlutoCell(value: report),
                                },
                              );
                            })
                            .toList();

                        return Column(
                          children: [
                            SizedBox(
                              height: (rows.length * rowHeight) + headerHeight,
                              child: PlutoGrid(
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
