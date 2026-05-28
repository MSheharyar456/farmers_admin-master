// screens/user_management/deleted_users_screen.dart
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

import 'package:farmers_admin/models/deleted_user_model.dart';
import 'package:farmers_admin/services/deleted_users_api_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/screens/user_management/deleted_user_detail_screen.dart';

class DeletedUsersScreen extends StatefulWidget {
  const DeletedUsersScreen({super.key});

  @override
  State<DeletedUsersScreen> createState() => _DeletedUsersScreenState();
}

class _DeletedUsersScreenState extends State<DeletedUsersScreen> {
  late DeletedUsersApiService _apiService;
  List<DeletedUserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  late PlutoGridStateManager _gridManager;

  // Pagination
  int _currentPage = 1;
  int _rowsPerPage = 50;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
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
        _totalCount = users.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load deleted users: $e';
        _isLoading = false;
      });
    }
  }

  void _onViewDetails(DeletedUserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeletedUserDetailScreen(userId: user.uid),
      ),
    );
  }

  List<PlutoColumn> _buildColumns() {
    return [
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
      ),
      PlutoColumn(
        title: 'Phone',
        field: 'phone',
        type: PlutoColumnType.text(),
        width: 150,
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
        width: 120,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final rowData = rendererContext.row.cells;
          final userId = rowData['uid']?.value as String? ?? '';
          final user = _users.firstWhere((u) => u.uid == userId, orElse: () => _users.first);
          return TextButton(
            onPressed: () => _onViewDetails(user),
            child: const Text('View Details'),
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows() {
    return _users.map((user) {
      return PlutoRow(cells: {
        'uid': PlutoCell(value: user.uid),
        'username': PlutoCell(value: user.userName),
        'email': PlutoCell(value: user.userEmail),
        'phone': PlutoCell(value: user.phoneComplete ?? 'N/A'),
        'deletedAt': PlutoCell(
          value: user.deletedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(user.deletedAt!)
              : null,
        ),
        'postsCount': PlutoCell(value: 0), // Will be populated from details
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.of(context).size.width >= 1024)
              Expanded(
                child: SideMenu(),
              ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deleted Users',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadUsers,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(_isLoading ? 'Loading...' : 'Reload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'View soft-deleted users and their data (read-only)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Stats
                    if (_totalCount > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              '$_totalCount users pending deletion',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Error
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
                    // Grid
                    Expanded(
                      child: _isLoading && _users.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : _users.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No deleted users found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Deleted users will appear here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : PlutoGrid(
                                  columns: _buildColumns(),
                                  rows: _buildRows(),
                                  mode: PlutoGridMode.select,
                                  onLoaded: (event) {
                                    _gridManager = event.stateManager;
                                    _gridManager.setPageSize(_rowsPerPage);
                                    _gridManager.setPage(_currentPage);
                                  },
                                  configuration: PlutoGridConfiguration(
                                    style: PlutoGridStyleConfig(
                                      gridBackgroundColor: Colors.white,
                                      activatedColor: Colors.blue[50]!,
                                      activatedBorderColor: Colors.blue,
                                    ),
                                  ),
                                ),
                    ),
                    // Pagination
                    if (_users.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() => _currentPage--);
                                      _gridManager.setPage(_currentPage);
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('Page $_currentPage'),
                            IconButton(
                              onPressed: _currentPage * _rowsPerPage < _totalCount
                                  ? () {
                                      setState(() => _currentPage++);
                                      _gridManager.setPage(_currentPage);
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
