// screens/user_management/deleted_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import 'package:farmers_admin/models/deleted_user_model.dart';
import 'package:farmers_admin/services/deleted_users_api_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/screens/user_management/deleted_user_detail_screen.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeletedUsersScreen extends StatefulWidget {
  const DeletedUsersScreen({super.key});

  @override
  State<DeletedUsersScreen> createState() => _DeletedUsersScreenState();
}

class _DeletedUsersScreenState extends State<DeletedUsersScreen> {
  late DeletedUsersApiService _apiService;
  List<DeletedUserModel> _users = [];
  bool _isLoading = false;
  bool _isDeletingUser = false;
  bool _isGridLoaded = false;
  PlutoGridStateManager? _stateManager;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _pendingSearchQuery = '';
  String? _selectedStatus;
  String? _pendingStatus;
  final double rowHeight = 40;
  final double headerHeight = 50;

  // Pagination
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AdminServerAuthService>(
        context,
        listen: false,
      );
      _apiService = DeletedUsersApiService(authService);
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _apiService.getDeletedUsers(limit: 500);
      setState(() {
        _users = users;
        _currentPage = 1;
        _isLoading = false;
      });
      if (mounted && _isGridLoaded && _stateManager != null) {
        final rows = _buildRows();
        _stateManager!.removeAllRows();
        if (rows.isNotEmpty) _stateManager!.appendRows(rows);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load deleted users: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeletedUserModel> get _filteredUsers {
    return _users.where((user) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesSearch =
            user.userName.toLowerCase().contains(query) ||
            user.userEmail.toLowerCase().contains(query) ||
            (user.phoneComplete ?? '').toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        if (_selectedStatus == 'Verified' && !user.isVerified) return false;
        if (_selectedStatus == 'Unverified' && user.isVerified) return false;
      }

      return true;
    }).toList();
  }

  List<DeletedUserModel> get _paginatedUsers {
    final filtered = _filteredUsers;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final count = _filteredUsers.length;
    return count == 0 ? 0 : (count / _rowsPerPage).ceil();
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _pendingSearchQuery.trim();
      _selectedStatus = _pendingStatus;
      _currentPage = 1;
    });
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
    }
  }

  void _onViewDetails(DeletedUserModel user) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => DeletedUserDetailScreen(userId: user.uid),
          ),
        )
        .then((value) {
          if (value == true && mounted) {
            _loadUsers();
          }
        });
  }

  Future<void> _onDeleteUser({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    if (_isDeletingUser) return;

    await showDeleteDialog(
      context: context,
      title: 'Permanently Delete User',
      message:
          'Are you sure you want to permanently delete "$userName" and all their data? This action cannot be undone.',
      confirmText: 'Yes, Delete Forever',
      cancelText: 'Cancel',
      onConfirm: () async {
        setState(() => _isDeletingUser = true);
        try {
          await _apiService.purgeDeletedUser(userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'User "$userName" permanently deleted successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Replace this screen with a fresh instance to fully reload the page
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DeletedUsersScreen()),
              );
              return;
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete user: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isDeletingUser = false);
          }
        }
      },
    );
  }

  List<PlutoColumn> _buildColumns() {
    return [
      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'UID',
        field: 'uid',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Username',
        field: 'username',
        type: PlutoColumnType.text(),
        width: 150,
        enableSorting: true,
        enableFilterMenuItem: true,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        width: 200,
        enableSorting: true,
        enableFilterMenuItem: true,
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
      PlutoColumn(
        title: 'Phone',
        field: 'phone',
        type: PlutoColumnType.text(),
        width: 150,
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
      PlutoColumn(
        title: 'Deleted Date',
        field: 'deletedAt',
        type: PlutoColumnType.date(),
        width: 120,
        enableSorting: true,
      ),
      PlutoColumn(
        title: 'Posts',
        field: 'postsCount',
        type: PlutoColumnType.number(),
        width: 80,
        enableSorting: true,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 150,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final rowData = rendererContext.row.cells;
          final userId = rowData['uid']?.value as String? ?? '';
          final userName =
              rowData['username']?.value as String? ?? 'Deleted user';
          final userEmail = rowData['email']?.value as String? ?? '';
          final user = _users.firstWhere(
            (u) => u.uid == userId,
            orElse: () => _users.first,
          );
          return Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    tooltip: 'Show Details',
                    onPressed: () => _onViewDetails(user),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 14,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete User',
                    onPressed: _isDeletingUser
                        ? null
                        : () => _onDeleteUser(
                            userId: userId,
                            userName: userName,
                            userEmail: userEmail,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows() {
    return List.generate(_paginatedUsers.length, (index) {
      final user = _paginatedUsers[index];
      final rowNumber = (_currentPage - 1) * _rowsPerPage + index + 1;
      return PlutoRow(
        cells: {
          'no': PlutoCell(value: rowNumber),
          'uid': PlutoCell(value: user.uid),
          'username': PlutoCell(value: user.userName),
          'email': PlutoCell(value: user.userEmail),
          'phone': PlutoCell(value: user.phoneComplete ?? 'N/A'),
          'deletedAt': PlutoCell(
            value: user.deletedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(user.deletedAt!)
                : null,
          ),
          'postsCount': PlutoCell(value: user.postsCount),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final actualRowCount = _paginatedUsers.length;
    final gridHeight = (actualRowCount * rowHeight) + headerHeight;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.of(context).size.width >= 1024)
              const SizedBox(width: 200, child: SideMenu()),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 40,
                    vertical: isMobile ? 12 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deleted Users',
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
                                  'Dashboard / Deleted Users',
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
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadUsers,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isLoading ? 'Loading...' : 'Reload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green, // button background color
                              foregroundColor:
                                  Colors.white, // icon & text color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Text(
                      //   'View soft-deleted users and their data (read-only)',
                      //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      //     color: Colors.grey[600],
                      //   ),
                      // ),
                      const SizedBox(height: 20),
                      _buildFilters(context, isMobile),
                      const SizedBox(height: 10),
                      // const SizedBox(height: 10),
                      if (_isLoading && _users.isEmpty)
                        Container(
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: LoadingOverlay(
                              text: 'Loading...',
                              showBackdrop: false,
                            ),
                          ),
                        )
                      else if (_filteredUsers.isEmpty)
                        _buildEmptyState(
                          title: _users.isEmpty
                              ? 'No deleted users found'
                              : 'No users found matching your filters',
                          message: _users.isEmpty
                              ? 'Deleted users will appear here'
                              : 'Try a different search',
                        )
                      else ...[
                        const SizedBox(height: 16),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red[800]),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_error != null) const SizedBox(height: 16),
                        SizedBox(
                          height: gridHeight,
                          child: PlutoGrid(
                            key: ValueKey('$_currentPage-$_rowsPerPage-$_searchQuery-$_selectedStatus'),
                            columns: _buildColumns(),
                            rows: _buildRows(),
                            onLoaded: (event) {
                              _stateManager = event.stateManager;
                              _stateManager!.setShowColumnFilter(false);
                              setState(() => _isGridLoaded = true);
                            },
                            mode: PlutoGridMode.select,
                            configuration: PlutoGridConfiguration(
                              columnSize: const PlutoGridColumnSizeConfig(
                                autoSizeMode: PlutoAutoSizeMode.scale,
                              ),
                              style: PlutoGridStyleConfig(
                                gridBackgroundColor: Colors.white,
                                activatedColor: Colors.blue[50]!,
                                activatedBorderColor: Colors.blue,
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
                          ),
                        ),

                        _buildPaginationFooter(context, isMobile),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isMobile) {
    return isMobile
        ? Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or contact...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) {
                  _pendingSearchQuery = val;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _pendingStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: const Text("Status"),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 150,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text("All"),
                        ),
                        DropdownMenuItem<String?>(
                          value: "Verified",
                          child: Text("Verified"),
                        ),
                        DropdownMenuItem<String?>(
                          value: "Unverified",
                          child: Text("Unverified"),
                        ),
                      ],
                      onChanged: (val) {
                        _pendingStatus = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _pendingSearchQuery = '';
                            _searchQuery = '';
                            _pendingStatus = null;
                            _selectedStatus = null;
                            _currentPage = 1;
                            _applyFilters();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("REMOVE FILTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
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
                    style: const TextStyle(fontSize: 12),
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search by name, email, or contact...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (val) {
                      _pendingSearchQuery = val;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 38,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _pendingStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 0,
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                    hint: const Text("Status", style: TextStyle(fontSize: 12)),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 150,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text("All", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem<String?>(
                        value: "Verified",
                        child: Text("Verified", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem<String?>(
                        value: "Unverified",
                        child: Text(
                          "Unverified",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      _pendingStatus = val;
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
                            _pendingSearchQuery = '';
                            _searchQuery = '';
                            _pendingStatus = null;
                            _selectedStatus = null;
                            _currentPage = 1;
                            _applyFilters();
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
          );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/image_farm_nothing_remains.png', height: 150),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context, bool isMobile) {
    final totalPages = _totalPages;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 5,
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
                      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                      onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                    ),
                    Text(
                      '$_currentPage / $totalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: _currentPage < totalPages
                          ? _goToNextPage
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          items: [5, 10, 20, 50]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e',
                                    style: const TextStyle(fontSize: 12),
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
                      style: TextStyle(color: Colors.black54, fontSize: 12),
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
                  onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                ),
                ...List.generate(totalPages > 7 ? 7 : totalPages, (index) {
                  int pageNum;
                  if (totalPages <= 7) {
                    pageNum = index + 1;
                  } else if (_currentPage <= 4) {
                    pageNum = index + 1;
                  } else if (_currentPage >= totalPages - 3) {
                    pageNum = totalPages - 6 + index;
                  } else {
                    pageNum = _currentPage - 3 + index;
                  }

                  final isActive = pageNum == _currentPage;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = pageNum);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
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
                        borderRadius: BorderRadius.circular(5),
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
                }),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onPressed: _currentPage < totalPages ? _goToNextPage : null,
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          items: [5, 10, 20, 50]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e',
                                    style: const TextStyle(fontSize: 12),
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
    );
  }
}
