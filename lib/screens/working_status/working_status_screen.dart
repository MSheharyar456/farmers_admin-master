import 'dart:async';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/models/working_status.dart';
import 'package:farmers_admin/screens/working_status/add_working_status.dart';
import 'package:farmers_admin/screens/working_status/edit_working_status.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';

class WorkingStatusManagementScreen extends StatefulWidget {
  const WorkingStatusManagementScreen({super.key});

  @override
  State<WorkingStatusManagementScreen> createState() => _WorkingStatusManagementScreenState();
}

class _WorkingStatusManagementScreenState extends State<WorkingStatusManagementScreen> {
  late PlutoGridStateManager stateManager;
  late DatabaseReference _dbRef;
  List<WorkingStatus> _workingStatuses = [];
  StreamSubscription<DatabaseEvent>? _workingStatusSubscription;
  bool _isGridLoaded = false;
  bool _isLoading = true;
  final double rowHeight = 45;
  final double headerHeight = 50;

  String _searchQuery = '';
  String? _selectedButtonStatus;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  List<WorkingStatus> get _filteredStatuses => _workingStatuses.where(_matchesFilters).toList();
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
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final value = ctx.cell.value?.toString() ?? 'false';
          final isEnabled = value.toLowerCase() == 'true';
          final statusColor = isEnabled ? Colors.green : Colors.grey;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isEnabled ? 'Enabled' : 'Disabled',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
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
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final value = ctx.cell.value?.toString() ?? 'false';
          final isWrong = value.toLowerCase() == 'true';
          final statusColor = isWrong ? Colors.red : Colors.green;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isWrong ? 'Yes' : 'No',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
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
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'images/ic_farm_edit.svg',
                    width: 20,
                    height: 20,
                    color: Colors.blue,
                  ),
                  tooltip: 'Edit Status',
                  splashRadius: 20,
                  onPressed: () {
                    try {
                      final status = _workingStatuses.firstWhere((s) => s.statusId == statusId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditWorkingStatusScreen(status: status),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: Could not find status with ID $statusId')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'images/ic_farm_trash.svg',
                    width: 20,
                    height: 20,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete Status',
                  splashRadius: 20,
                  onPressed: () async {
                    await showDeleteDialog(
                      context: context,
                      title: "Delete Working Status",
                      message: "Are you sure you want to delete this working status?",
                      onConfirm: () async {
                        await FirebaseDatabase.instance.ref('workingStatus/$statusId').remove();
                        setState(() {});
                      },
                    );
                  },
                ),
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
    _dbRef = FirebaseDatabase.instance.ref().child('workingStatus');
    _listenForWorkingStatuses();
  }

  void _listenForWorkingStatuses() {
    _workingStatusSubscription = _dbRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return;

      if (_isLoading) {
        setState(() => _isLoading = false);
      }

      if (event.snapshot.value != null) {
        final rawData = event.snapshot.value as Map<dynamic, dynamic>;
        final List<WorkingStatus> loadedStatuses = [];
        rawData.forEach((key, value) {
          if (value is Map) {
            final statusMap = Map<dynamic, dynamic>.from(value);
            loadedStatuses.add(WorkingStatus.fromMap(key, statusMap));
          }
        });
        setState(() {
          _workingStatuses = loadedStatuses;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      } else {
        setState(() => _workingStatuses = []);
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    });
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
            'isEnableButton': PlutoCell(value: status.isEnableButton.toString()),
            'isSomethingWrong': PlutoCell(value: status.isSomethingWrong.toString()),
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
    _workingStatusSubscription?.cancel();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      if (_isGridLoaded) _updatePlutoGridRows();
    });
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedButtonStatus != null;

    if (hasFilters && _workingStatuses.isNotEmpty) {
      return _buildNoResultsState();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Image.asset(
                  'images/image_farm_nothing_remains.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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
              "You're all caught up!",
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No working statuses found",
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey,
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
                padding: EdgeInsets.all(isMobile ? 12 : 15),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
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
                                    const AddWorkingStatusScreen()),
                              );
                            },

                            icon: const Icon(Icons.add,
                                color: Colors.white),
                            label: const Text("Add Working Status",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Dashboard / Working Status List",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const AddWorkingStatusScreen()),
                            );
                          },
                          icon: const Icon(Icons.add,
                              color: Colors.white),
                          label: const Text("Add Working Status",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                                  color: Colors.green, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'images/ic_farm_filter.svg',
                                  height: 20,
                                  width: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "APPLY FILTERS",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            width: isTablet ? 200 : 300,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.green, width: 2),
                                ),
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedButtonStatus,
                            isExpanded: true,
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            hint: const Text("Button Status"),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                  value: null, child: Text("All")),
                              DropdownMenuItem(
                                  value: "Enabled",
                                  child: Text("Enabled")),
                              DropdownMenuItem(
                                  value: "Disabled",
                                  child: Text("Disabled")),
                            ],
                            onChanged: (val) => setState(
                                    () => _selectedButtonStatus = val),
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
                                  horizontal: 16, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'images/ic_farm_filter.svg',
                                  height: 20,
                                  width: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "APPLY FILTERS",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid Section
                    SizedBox(
                      child: _isLoading
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.green))
                          : _workingStatuses.isEmpty ||
                          (_isGridLoaded && _filteredStatuses.isEmpty)
                          ? _buildEmptyState()
                          : Container(
                        color: Colors.white,
                        height: (_paginatedStatuses.length *
                            rowHeight) +
                            headerHeight,
                        child: PlutoGrid(
                          columns: _getColumns(),
                          rows: [],
                          onLoaded: (event) {
                            stateManager = event.stateManager;
                            stateManager.setShowColumnFilter(false);
                            setState(() => _isGridLoaded = true);
                            if (_workingStatuses.isNotEmpty)
                              _updatePlutoGridRows();
                          },
                          configuration: PlutoGridConfiguration(
                            columnSize:
                            const PlutoGridColumnSizeConfig(
                              autoSizeMode: PlutoAutoSizeMode.scale,
                            ),
                            style: PlutoGridStyleConfig(
                              rowHeight: 45,
                              columnTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold),
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
                          vertical: isMobile ? 12 : 16,
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
                                      color: Colors.grey),
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
                                      color: Colors.grey),
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
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _rowsPerPage,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18),
                                      items: [5, 10, 20, 50]
                                          .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e'),
                                      ))
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
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 16, color: Colors.grey),
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
                                        horizontal: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isActive
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey.shade300,
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$pageNum',
                                      style: TextStyle(
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
                              icon: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
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
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
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
                                          size: 18),
                                      items: [5, 10, 20, 50]
                                          .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e'),
                                      ))
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