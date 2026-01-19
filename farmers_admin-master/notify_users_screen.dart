import 'dart:async';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/screens/notify_users/add_notify_user.dart';
import 'package:farmers_admin/screens/notify_users/edit_notify_user.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';

class NotifyUsersScreen extends StatefulWidget {
  const NotifyUsersScreen({super.key});

  @override
  State<NotifyUsersScreen> createState() => _NotifyUsersScreenState();
}

class _NotifyUsersScreenState extends State<NotifyUsersScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const NotifyUsersContent(),
    );
  }
}

class NotifyUsersContent extends StatefulWidget {
  const NotifyUsersContent({super.key});

  @override
  State<NotifyUsersContent> createState() => _NotifyUsersContentState();
}

class _NotifyUsersContentState extends State<NotifyUsersContent> {
  late PlutoGridStateManager stateManager;
  late DatabaseReference _dbRef;
  List<UserModel> _users = [];
  StreamSubscription<DatabaseEvent>? _usersSubscription;
  bool _isGridLoaded = false;
  bool _isLoading = true;
  final double rowHeight = 40;
  final double headerHeight = 50;

  String _searchQuery = '';
  String _appliedSearchQuery = '';
  late TextEditingController _searchController;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  List<UserModel> get _filteredUsers => 
      _users.where(_matchesFilters).toList();
  int get totalPages => (_filteredUsers.length / _rowsPerPage).ceil();

  List<UserModel> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length 
          ? _filteredUsers.length 
          : endIndex,
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
        title: 'User ID',
        field: 'id',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
      ),
      PlutoColumn(
        title: 'User Name',
        field: 'name',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 200,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 250,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Login Date',
        field: 'date',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 160,
        minWidth: 160,
        renderer: (rendererContext) {
          final userId = rendererContext.row.cells['id']!.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero, // ✅ removes default padding
                  constraints: const BoxConstraints(), // ✅ removes extra size
                  icon: const Icon(
                    Icons.add,
                    size: 14,
                    color: Colors.blue,
                  ),
                  tooltip: 'Add Notification',
                  splashRadius: 20,
                  onPressed: () {
                    try {
                      final user = _users.firstWhere(
                        (u) => u.uid == userId
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditNotifyUserScreen(
                            userId: user.uid,
                            userName: user.userName,
                            userEmail: user.userEmail,
                            userFCMToken: user.userFCMToken,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: Could not find user with ID $userId')
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero, // ✅ removes default padding
                  constraints: const BoxConstraints(), // ✅ removes extra size
                  icon: const Icon(
                    Icons.visibility,
                    size: 14,
                    color: Colors.green,
                  ),
                  tooltip: 'Show Details',
                  splashRadius: 20,
                  onPressed: () {
                    try {
                      final user = _users.firstWhere(
                        (u) => u.uid == userId
                      );
                      _showUserDetails(user);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: Could not find user with ID $userId')
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  void _showUserDetails(UserModel user) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedDate = user.userLoginDate > 0
        ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(user.userLoginDate))
        : 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.green.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'User Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('User ID', user.uid),
                      const SizedBox(height: 16),
                      _buildDetailRow('Name', user.userName),
                      const SizedBox(height: 16),
                      _buildDetailRow('Email', user.userEmail),
                      const SizedBox(height: 16),
                      _buildDetailRow('Status', user.status),
                      const SizedBox(height: 16),
                      _buildDetailRow('Verified', user.isVerified ? 'Yes' : 'No'),
                      const SizedBox(height: 16),
                      _buildDetailRow('Date of Birth', user.dob),
                      const SizedBox(height: 16),
                      if (user.userScore != null) ...[
                        _buildDetailRow('Score', user.userScore!),
                        const SizedBox(height: 16),
                      ],
                      _buildDetailRow('Login Date', formattedDate),
                      const SizedBox(height: 16),
                      _buildDetailRow('Post Limit', user.userPostLimit.toString()),
                      const SizedBox(height: 16),
                      _buildDetailRow('Following', user.userFollowing.toString()),
                    ],
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _dbRef = FirebaseDatabase.instance.ref().child('usersAuthData');
    _listenForUsers();
  }

  void _listenForUsers() {
    _usersSubscription = _dbRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return;

      if (_isLoading) {
        setState(() => _isLoading = false);
      }

      if (event.snapshot.value != null) {
        final rawData = event.snapshot.value;
        final List<UserModel> loadedUsers = [];

        if (rawData is Map<dynamic, dynamic>) {
          rawData.forEach((key, value) {
            if (value is Map) {
              final userMap = Map<String, dynamic>.from(value);
              // 🔧 FIX: Extract userId from userMap instead of using database key
              final userId = userMap['userId']?.toString() ?? key.toString();
              debugPrint('✅ Loading user - DB Key: $key, Real userId: $userId');
              loadedUsers.add(
                  UserModel.fromFirebase(userId, userMap)
              );
            }
          });

          // Sort by login date, newest first
          loadedUsers.sort((a, b) {
            return b.userLoginDate.compareTo(a.userLoginDate);
          });
        }
        setState(() {
          _users = loadedUsers;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      } else {
        setState(() => _users = []);
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    });
  }
  bool _matchesFilters(UserModel user) {
    if (_appliedSearchQuery.isNotEmpty) {
      final name = user.userName.toLowerCase();
      final email = user.userEmail.toLowerCase();
      final uid = user.uid.toLowerCase();
      final status = user.status.toLowerCase();

      if (!name.contains(_appliedSearchQuery) &&
          !email.contains(_appliedSearchQuery) &&
          !uid.contains(_appliedSearchQuery) &&
          !status.contains(_appliedSearchQuery)) {
        return false;
      }
    }
    return true;
  }

  void _updatePlutoGridRows() {
    final newRows = <PlutoRow>[];
    int counter = 1;

    for (final user in _paginatedUsers) {
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      final formattedDate = user.userLoginDate > 0
          ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(user.userLoginDate))
          : 'N/A';

      newRows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()),
            'id': PlutoCell(value: user.uid),
            'name': PlutoCell(value: user.userName),
            'email': PlutoCell(value: user.userEmail),
            'status': PlutoCell(value: user.status),
            'date': PlutoCell(value: formattedDate),
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
    _usersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _appliedSearchQuery = _searchQuery.toLowerCase();
      _currentPage = 1;
      if (_isGridLoaded) _updatePlutoGridRows();
    });
  }

  Widget _buildEmptyState() {
    final hasFilters = _appliedSearchQuery.isNotEmpty;

    if (hasFilters && _users.isNotEmpty) {
      return _buildNoResultsState();
    }

    return SizedBox(
      height: 500,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 250),
                child: Image.asset(
                  'images/image_farm_nothing_remains.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "No users available",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "No authenticated users found",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
            Image.asset(
              'images/image_farm_nothing_remains.png',
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              "No results found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Try adjusting your search filters",
              style: TextStyle(
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Users',
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
                                        "Dashboard / Users List",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(

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
                                          Icon(
                                            Icons.add,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Add Notification",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'User Notification',
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
                                    'Dashboard / Users Notification',
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

                                child: ElevatedButton(
                                  onPressed: (){
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddNotifyUserScreen(

                                        ),
                                      ),
                                    );
                                  },


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
                                      Icon(
                                        Icons.add,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Add Notification",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                        ),
                                      ),
                                    ],
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
                              SizedBox(
                                width: double.infinity,
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
                                        height: 20,
                                        width: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "APPLY FILTERS",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                  height: 38,
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      hintText: 'Search...',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      prefixIcon: const Icon(Icons.search, size: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.green,
                                          width: 1,
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
                                      const Text(
                                        "APPLY FILTERS",
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
                            ],
                          ),
                    const SizedBox(height: 10),

                    // Grid Section
                    SizedBox(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.green),
                            )
                          : _users.isEmpty
                              ? _buildEmptyState()
                              : _filteredUsers.isEmpty
                                  ? _buildNoResultsState()
                                  : Container(
                                      color: Colors.white,
                                      height: (_paginatedUsers.length * rowHeight) +
                                          headerHeight,
                                      child: PlutoGrid(
                                        columns: _getColumns(),
                                        rows: [],
                                        onLoaded: (event) {
                                          stateManager = event.stateManager;
                                          stateManager.setShowColumnFilter(false);
                                          setState(() => _isGridLoaded = true);
                                          if (_users.isNotEmpty)
                                            _updatePlutoGridRows();
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
                    ),

                    // Pagination Footer
                    if (!_isLoading && _filteredUsers.isNotEmpty)
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
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 14,
                                            ),
                                            items: [5, 10, 20, 50]
                                                .map((e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text('$e', style: const TextStyle(fontSize: 12)),
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
                                        } else if (_currentPage >= totalPages - 3) {
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
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                            borderRadius: BorderRadius.circular(5),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(5),
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
                                                .map((e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text('$e', style: const TextStyle(fontSize: 12)),
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

