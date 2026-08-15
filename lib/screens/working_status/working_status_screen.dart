import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/working_status.dart';
import 'package:farmers_admin/screens/working_status/add_working_status.dart';
import 'package:farmers_admin/screens/working_status/edit_working_status.dart';
import 'package:farmers_admin/services/admin_working_status_api_service.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:farmers_admin/services/permission_helper.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';

class WorkingStatusManagementScreen extends StatefulWidget {
  const WorkingStatusManagementScreen({super.key});

  @override
  State<WorkingStatusManagementScreen> createState() =>
      _WorkingStatusManagementScreenState();
}

class _WorkingStatusManagementScreenState
    extends State<WorkingStatusManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const DashboardContent(),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  late PlutoGridStateManager stateManager;
  List<WorkingStatus> _workingStatuses = [];
  bool _isGridLoaded = false;
  bool _isLoading = true;
  final double rowHeight = 40;
  final double headerHeight = 50;

  String _searchQuery = '';
  String? _selectedButtonStatus;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Temporary variables for filter input before applying
  String _tempSearchQuery = '';
  String? _tempSelectedButtonStatus;
  late TextEditingController _searchController;

  // Permission states
  bool _canEdit = true;

  List<WorkingStatus> get _filteredStatuses =>
      _workingStatuses.where(_matchesFilters).toList();
  int get totalPages => (_filteredStatuses.length / _rowsPerPage).ceil();

  List<WorkingStatus> get _paginatedStatuses {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredStatuses.sublist(
      startIndex,
      endIndex > _filteredStatuses.length ? _filteredStatuses.length : endIndex,
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
        title: 'Status ID',
        field: 'id',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Title',
        field: 'workingTitle',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 200,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Details',
        field: 'workingDetails',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 300,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'Status Enabled',
        field: 'isEnableButton',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 125,
        minWidth: 125,
        renderer: (ctx) {
          final value = ctx.cell.value?.toString() ?? 'false';
          final isEnabled = value.toLowerCase() == 'true';
          final statusColor = isEnabled ? Colors.green : Colors.grey;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isEnabled ? 'Enabled' : 'Disabled',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Status Error',
        field: 'isSomethingWrong',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 125,
        minWidth: 125,
        renderer: (ctx) {
          final value = ctx.cell.value?.toString() ?? 'false';
          final isWrong = value.toLowerCase() == 'true';
          final statusColor = isWrong ? Colors.red : Colors.green;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isWrong ? 'Yes' : 'No',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
        renderer: (rendererContext) {
          final statusId = rendererContext.row.cells['id']!.value;
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
                    tooltip: 'Edit Status',
                    splashRadius: 20,
                    onPressed: () {
                      try {
                        final status = _workingStatuses.firstWhere(
                          (s) => s.statusId == statusId,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditWorkingStatusScreen(status: status),
                          ),
                        ).then((_) => _loadWorkingStatuses());
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: Could not find status with ID $statusId',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              if (!_canEdit)
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
    _loadWorkingStatuses();
  }

  Future<void> _loadPermissions() async {
    final canEdit = await PermissionHelper.canEdit();
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
      });
    }
  }

  Future<void> _loadWorkingStatuses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final service = context.read<AdminWorkingStatusApiService>();
      final list = await service.getWorkingStatus();
      final statuses = list.map((e) {
        final id = e['id']?.toString() ?? '';
        return WorkingStatus.fromServerMap(id, e);
      }).toList();
      if (mounted) {
        setState(() {
          _workingStatuses = statuses;
          _isLoading = false;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _workingStatuses = [];
          _isLoading = false;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    }
  }

  bool _matchesFilters(WorkingStatus status) {
    if (_searchQuery.isNotEmpty) {
      final title = status.workingTitle?.toLowerCase() ?? '';
      final details = status.workingDetails?.toLowerCase() ?? '';
      if (!title.contains(_searchQuery) && !details.contains(_searchQuery)) {
        return false;
      }
    }

    if (_selectedButtonStatus != null) {
      final isEnabled = status.isEnableButton ? "Enabled" : "Disabled";
      if (_selectedButtonStatus != isEnabled) return false;
    }

    return true;
  }

  void _updatePlutoGridRows() {
    final newRows = <PlutoRow>[];
    int counter = 1;

    for (final status in _paginatedStatuses) {
      newRows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()),
            'id': PlutoCell(value: status.statusId ?? ''),
            'workingTitle': PlutoCell(value: status.workingTitle ?? ''),
            'workingDetails': PlutoCell(value: status.workingDetails ?? ''),
            'isEnableButton': PlutoCell(
              value: status.isEnableButton.toString(),
            ),
            'isSomethingWrong': PlutoCell(
              value: status.isSomethingWrong.toString(),
            ),
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
      _searchQuery = _tempSearchQuery;
      _selectedButtonStatus = _tempSelectedButtonStatus;
      _currentPage = 1;
      if (_isGridLoaded) _updatePlutoGridRows();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/image_farm_nothing_remains.png', height: 150),

            const SizedBox(height: 24),
            Text(
              "No working statuses available",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Add your first working status to get started",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
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
              "No working statuses found matching your filters",
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
                                    'Working Status',
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
                                    "Dashboard / Working Status List",
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
                                            const AddWorkingStatusScreen(),
                                      ),
                                    ).then((_) => _loadWorkingStatuses());
                                  },

                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Add Working Status",
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Working Status',
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
                                    'Dashboard / Working Status List',
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
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddWorkingStatusScreen(),
                                      ),
                                    ).then((_) => _loadWorkingStatuses());
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    "Add Working Status",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 20),

                    // Filters Section
                    isMobile
                        ? Column(
                            children: [
                              TextField(
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
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _tempSearchQuery = val.toLowerCase();
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
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                          _tempSearchQuery = '';
                                          _searchQuery = '';
                                          _tempSelectedButtonStatus = null;
                                          _selectedButtonStatus = null;
                                          _currentPage = 1;
                                          if (_isGridLoaded) _updatePlutoGridRows();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                    style: const TextStyle(fontSize: 12),
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
                                    controller: _searchController,
                                    onChanged: (val) {
                                      setState(() {
                                        _tempSearchQuery = val.toLowerCase();
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
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _tempSelectedButtonStatus,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
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
                                    hint: const Text(
                                      "Button Status",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    dropdownColor: Colors.white,
                                    items: const [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          "All",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: "Enabled",
                                        child: Text(
                                          "Enabled",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: "Disabled",
                                        child: Text(
                                          "Disabled",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) => setState(
                                      () => _tempSelectedButtonStatus = val,
                                    ),
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
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
                                            _tempSearchQuery = '';
                                            _searchQuery = '';
                                            _tempSelectedButtonStatus = null;
                                            _selectedButtonStatus = null;
                                            _currentPage = 1;
                                            if (_isGridLoaded) _updatePlutoGridRows();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
                    Container(
                      height: _isLoading
                          ? 300
                          : (_paginatedStatuses.length * rowHeight) +
                                headerHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isLoading
                          ? const LoadingOverlay(
                              text: 'Loading...',
                              showBackdrop: false,
                            )
                          : _workingStatuses.isEmpty
                          ? _buildEmptyState()
                          : _filteredStatuses.isEmpty
                          ? _buildNoResultsState()
                          : Container(
                              color: Colors.white,
                              height:
                                  (_paginatedStatuses.length * rowHeight) +
                                  headerHeight,
                              child: PlutoGrid(
                                columns: _getColumns(),
                                rows: [],
                                onLoaded: (event) {
                                  stateManager = event.stateManager;
                                  stateManager.setShowColumnFilter(false);
                                  setState(() => _isGridLoaded = true);
                                  if (_workingStatuses.isNotEmpty) {
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
                    if (!_isLoading && _filteredStatuses.isNotEmpty)
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
                                          size: 16,
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
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
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
                                            6,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _rowsPerPage,
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 18,
                                            ),
                                            items: [5, 10, 20, 50]
                                                .map(
                                                  (e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text('$e'),
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
                                      const SizedBox(width: 6),
                                      const Text(
                                        "/ Page",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
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
                                            vertical: 6,
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
