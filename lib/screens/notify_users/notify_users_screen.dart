import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/screens/notify_users/add_notify_user.dart';
import 'package:farmers_admin/screens/notify_users/edit_notify_user.dart';
import 'package:farmers_admin/viewmodels/user_viewmodel.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:flutter/services.dart';
import 'package:farmers_admin/services/admin_notification_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

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
  final double rowHeight = 40;
  final double headerHeight = 50;

  UserScreenViewModel? _viewModel;
  bool _isGridLoaded = false;

  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel = context.read<UserScreenViewModel>();
      _viewModel!.addListener(_onViewModelChanged);
      _initializeData();
    });
  }

  void _onViewModelChanged() {
    if (_isGridLoaded && mounted) _updatePlutoGridRows();
  }

  Future<void> _initializeData() async {
    if (!mounted || _viewModel == null) return;
    await _viewModel!.loadFromRepository();
  }

  void _updatePlutoGridRows() {
    if (!_isGridLoaded || !mounted) return;

    final viewModel = context.read<UserScreenViewModel>();
    final rows = _buildPlutoRows(
      viewModel,
      MediaQuery.of(context).size.width < 600,
    );

    stateManager.removeAllRows();
    if (rows.isNotEmpty) {
      stateManager.appendRows(rows);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _searchController.dispose();
    super.dispose();
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
            child: Consumer<UserScreenViewModel>(
              builder: (context, viewModel, _) {
                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 40,
                      vertical: isMobile ? 12 : 20,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context, isMobile),
                        const SizedBox(height: 20),
                        _buildFilters(context, viewModel, isMobile),
                        const SizedBox(height: 10),
                        _buildUsersList(context, viewModel, isMobile),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Notification',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dashboard / Users Notification",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedUsers.isNotEmpty) ...[
                        ElevatedButton(
                          onPressed: _showSelectedUsersNotificationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.send,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Send to Selected (${_selectedUsers.length})",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNotifyUserScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Add",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Notification',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Dashboard / Users Notification',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedUsers.isNotEmpty) ...[
                    ElevatedButton(
                      onPressed: _showSelectedUsersNotificationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send, size: 14, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            "Send to Selected (${_selectedUsers.length})",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddNotifyUserScreen(),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "All Notification",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
  }

  Widget _buildFilters(
    BuildContext context,
    UserScreenViewModel viewModel,
    bool isMobile,
  ) {
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
                  viewModel.setSearchQuery(val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: viewModel.pendingStatus,
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
                        viewModel.setSelectedStatus(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        viewModel.applyFilters();
                        if (_isGridLoaded) _updatePlutoGridRows();
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
                          SvgPicture.asset(
                            'images/ic_farm_filter.svg',
                            height: 20,
                            width: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "APPLY",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                        _searchController.clear();
                        viewModel.resetFilters();
                        if (_isGridLoaded) _updatePlutoGridRows();
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
                      child: const Text(
                        "REMOVE FILTER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                      viewModel.setSearchQuery(val);
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
                    value: viewModel.pendingStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
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
                      viewModel.setSelectedStatus(val);
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
                        onPressed: () {
                          viewModel.applyFilters();
                          if (_isGridLoaded) _updatePlutoGridRows();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
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
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                          viewModel.resetFilters();
                          if (_isGridLoaded) _updatePlutoGridRows();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          "CLEAR",
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
          );
  }

  Widget _buildUsersList(
    BuildContext context,
    UserScreenViewModel viewModel,
    bool isMobile,
  ) {
    if (viewModel.isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (viewModel.filteredUsers.isEmpty) {
      if (viewModel.isSourceDataEmpty) {
        return _buildEmptyState(
          isMobile: isMobile,
          title: "No users available",
          message: "Users will appear here",
        );
      } else {
        return _buildEmptyState(
          isMobile: isMobile,
          title: "You're all caught up!",
          message: "No users found matching your filters",
        );
      }
    }

    final List<PlutoColumn> columns = _getColumns(context, isMobile);
    final List<PlutoRow> rows = _buildPlutoRows(viewModel, isMobile);

    return Column(
      children: [
        SizedBox(
          height: (rows.length * rowHeight) + headerHeight,
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onRowChecked: (event) {
              setState(() {
                if (event.isAll == true) {
                  final currentRowsUsers = stateManager.rows
                      .map((r) => r.cells['userData']!.value as UserModel)
                      .toList();
                  if (event.isChecked == true) {
                    for (var user in currentRowsUsers) {
                      if (!_selectedUsers.any((u) => u.uid == user.uid)) {
                        _selectedUsers.add(user);
                      }
                    }
                  } else {
                    for (var user in currentRowsUsers) {
                      _selectedUsers.removeWhere((u) => u.uid == user.uid);
                    }
                  }
                } else if (event.row != null) {
                  final user = event.row!.cells['userData']!.value as UserModel;
                  if (event.isChecked == true) {
                    if (!_selectedUsers.any((u) => u.uid == user.uid)) {
                      _selectedUsers.add(user);
                    }
                  } else {
                    _selectedUsers.removeWhere((u) => u.uid == user.uid);
                  }
                }
              });
            },
            onLoaded: (event) {
              stateManager = event.stateManager;
              stateManager.setShowColumnFilter(false);
              setState(() => _isGridLoaded = true);
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
                oddRowColor: Colors.white,
                evenRowColor: Colors.grey.shade50,
              ),
            ),
          ),
        ),
        _buildPaginationFooter(context, viewModel, isMobile),
      ],
    );
  }

  List<PlutoColumn> _getColumns(BuildContext context, bool isMobile) {
    return [
      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: isMobile ? 50 : 60,
        enableRowChecked: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Full Name',
        field: 'fullName',
        type: PlutoColumnType.text(),
        width: isMobile ? 120 : 150,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: 'Email',
          field: 'email',
          type: PlutoColumnType.text(),
          width: 200,
          enableEditingMode: false,
        ),
      if (!isMobile)
        PlutoColumn(
          title: 'Login Date',
          field: 'dob',
          type: PlutoColumnType.text(),
          width: 150,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 115,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value?.toString() ?? 'N/A';
          Color statusColor = value == 'Verified'
              ? Colors.green
              : Colors.orange;
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
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 12,
                  ),
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
        width: 125,
        minWidth: 125,
        enableEditingMode: false,
        renderer: (ctx) {
          final user = ctx.row.cells['userData']?.value as UserModel?;
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
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, size: 14, color: Colors.blue),
                  tooltip: 'Add Notification',
                  onPressed: () {
                    if (user != null) {
                      print('User ID: ${user.uid}');
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
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.visibility,
                    size: 14,
                    color: Colors.green,
                  ),
                  tooltip: 'Show Details',
                  onPressed: () {
                    if (user != null) {
                      _showUserDetails(user);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'User Data',
        field: 'userData',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
    ];
  }

  void _showUserDetails(UserModel user) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedDate = user.userLoginDate > 0
        ? dateFormat.format(
            DateTime.fromMillisecondsSinceEpoch(user.userLoginDate),
          )
        : 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      _buildDetailRow(
                        'Status',
                        user.isVerified ? 'Verified' : 'Unverified',
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Login Date', formattedDate),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Post Limit',
                        user.userPostLimit.toString(),
                      ),
                    ],
                  ),
                ),
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
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  List<PlutoRow> _buildPlutoRows(UserScreenViewModel viewModel, bool isMobile) {
    return List.generate(viewModel.paginatedUsers.length, (index) {
      final user = viewModel.paginatedUsers[index];
      final rowNumber = viewModel.pagination.startIndex + index + 1;
      final isChecked = _selectedUsers.any((u) => u.uid == user.uid);

      return PlutoRow(
        checked: isChecked,
        cells: {
          'no': PlutoCell(value: rowNumber),
          'fullName': PlutoCell(value: user.userName),
          'email': PlutoCell(value: user.userEmail),
          'dob': PlutoCell(value: _formatTimestamp(user.userLoginDate)),
          'status': PlutoCell(
            value: user.isVerified ? 'Verified' : 'Unverified',
          ),
          'actions': PlutoCell(value: ''),
          'userData': PlutoCell(value: user),
        },
      );
    });
  }

  String _formatTimestamp(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "N/A";
    }
  }

  Widget _buildEmptyState({
    required bool isMobile,
    required String title,
    required String message,
  }) {
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

  Widget _buildPaginationFooter(
    BuildContext context,
    UserScreenViewModel viewModel,
    bool isMobile,
  ) {
    final pagination = viewModel.pagination;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: Colors.grey,
            ),
            onPressed: pagination.canGoPrevious
                ? () {
                    viewModel.goToPreviousPage();
                    _updatePlutoGridRows();
                  }
                : null,
          ),
          ...List.generate(
            pagination.totalPages > 7 ? 7 : pagination.totalPages,
            (index) {
              int pageNum = index + 1;
              bool isActive = pageNum == pagination.currentPage;
              return GestureDetector(
                onTap: () {
                  viewModel.setCurrentPage(pageNum);
                  _updatePlutoGridRows();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
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
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
            onPressed: pagination.canGoNext
                ? () {
                    viewModel.goToNextPage();
                    _updatePlutoGridRows();
                  }
                : null,
          ),
          const SizedBox(width: 20),
          DropdownButton<int>(
            value: pagination.rowsPerPage,
            items: [5, 10, 20, 50]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                viewModel.setRowsPerPage(val);
                _updatePlutoGridRows();
              }
            },
          ),
          const Text(
            " / Page",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showSelectedUsersNotificationDialog() {
    final titleController = TextEditingController(text: 'تطبيق محصولك');
    final messageController = TextEditingController();
    bool isSendingDialog = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('Send Notification to Selected Users'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You are about to send a notification to ${_selectedUsers.length} selected users.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Title*',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: const TextStyle(fontSize: 12),
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter notification title...',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Message*',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: const TextStyle(fontSize: 12),
                          controller: messageController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter notification message...',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSendingDialog
                      ? null
                      : () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSendingDialog
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty ||
                              messageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill out both title and message.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isSendingDialog = true);

                          try {
                            final authService =
                                Provider.of<AdminServerAuthService>(
                                  context,
                                  listen: false,
                                );
                            final authToken = authService.authToken;
                            if (authToken == null)
                              throw Exception('Auth token not found');

                            for (var user in _selectedUsers) {
                              await AdminNotificationService.sendNotification(
                                title: titleController.text.trim(),
                                message: messageController.text.trim(),
                                userId: user.uid,
                                type: 'admin_broadcast',
                                authToken: authToken,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Notification successfully sent to  users.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Clear selection
                            stateManager.toggleAllRowChecked(false);
                            setState(() {
                              _selectedUsers.clear();
                            });
                          } catch (e) {
                            setStateDialog(() => isSendingDialog = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: '),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: isSendingDialog
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Notification',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
