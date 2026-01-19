// screens/user_screen.dart - OPTIMIZED VERSION
import 'dart:async';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:farmers_admin/screens/user_management/edit_user_screen.dart';
import 'package:farmers_admin/viewmodels/user_viewmodel.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
import 'package:farmers_admin/services/permission_helper.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: ChangeNotifierProvider(
        create: (_) => UserScreenViewModel(repository: UserRepository()),
        child: const UserContent(),
      ),
    );
  }
}

class UserContent extends StatefulWidget {
  const UserContent({super.key});

  @override
  State<UserContent> createState() => _UserContentState();
}

class _UserContentState extends State<UserContent> {
  late PlutoGridStateManager stateManager;
  final double rowHeight = 40;
  final double headerHeight = 50;

  // Stream subscription
  StreamSubscription<List<UserModel>>? _userSubscription;
  bool _isGridLoaded = false;

  final TextEditingController _searchController = TextEditingController();

  // Permission states
  bool _canEdit = true;
  bool _canDelete = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _initializeData();
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

  void _initializeData() {
    final viewModel = context.read<UserScreenViewModel>();

    // Listen to user stream ONCE
    _userSubscription = UserRepository().getUsersStream().listen((users) {
      if (!mounted) return;
      viewModel.loadUsers(users);

      // Update grid only if it's already loaded
      if (_isGridLoaded) {
        _updatePlutoGridRows();
      }
    });
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
    _userSubscription?.cancel();
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
                        const SizedBox(
                          height: 10,
                        ), // Increased spacing to prevent dropdown overlap
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
              Text(
                "Customer's List",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Dashboard / Customer's List",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 15),
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
                      "Customer's List",
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Dashboard / Customer's List",
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
                  hintText: 'Search by name or email...',
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
                  // Store pending search query without applying filters
                  viewModel.setSearchQuery(val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: viewModel.pendingStatus,
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
                      menuMaxHeight: 150, // Limit menu height
                      isExpanded: true, // Ensure dropdown takes full width
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
                        // Store pending status without applying filters
                        viewModel.setSelectedStatus(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Apply filters when button is clicked
                      viewModel.applyFilters();
                      if (_isGridLoaded) _updatePlutoGridRows();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                    style: const TextStyle(
                      fontSize: 12,
                    ), // 👈 This controls the input text size
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search by name or email...',
                      hintStyle: TextStyle(fontSize: 12),
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
                      // Store pending search query without applying filters
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
                    initialValue: viewModel.pendingStatus,
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
                    ), // 👈 ADD THIS
                    hint: const Text("Status", style: TextStyle(fontSize: 12)),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 150, // Limit menu height
                    isExpanded: true, // Ensure dropdown takes full width
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
                      // Store pending status without applying filters
                      viewModel.setSelectedStatus(val);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters when button is clicked
                    viewModel.applyFilters();
                    if (_isGridLoaded) _updatePlutoGridRows();
                  },

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
          );
  }

  Widget _buildUsersList(
    BuildContext context,
    UserScreenViewModel viewModel,
    bool isMobile,
  ) {
    // Show loading only on initial load
    if (viewModel.isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    // Show empty state if no users
    // Show empty state if no users
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
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Full Name',
        field: 'fullName',
        type: PlutoColumnType.text(),
        width: isMobile ? 120 : 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Contact',
        field: 'contact',
        type: PlutoColumnType.text(),
        width: isMobile ? 110 : 130,
        enableEditingMode: false,
      ),
      if (!isMobile)
        PlutoColumn(
          title: 'Email',
          field: 'email',
          type: PlutoColumnType.text(),
          enableEditingMode: false,
        ),
      if (!isMobile)
        PlutoColumn(
          title: 'Login Date',
          field: 'dob',
          type: PlutoColumnType.text(),
          enableEditingMode: false,
        ),

      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 115,
        minWidth: 100,
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
                  maxLines: 1,
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
              if (_canEdit)
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_edit.svg',
                      width: 12,
                      height: 12,
                      color: Colors.blue,
                    ),

                    tooltip: 'Edit User',
                    splashRadius: 20,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    onPressed: () {
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditUserScreen(user: user.toMap()),
                          ),
                        );
                      }
                    },
                  ),
                ),
              if (_canEdit && _canDelete && !isMobile) const SizedBox(width: 8),
              if (_canDelete && !isMobile)
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_trash.svg',
                      width: 12,
                      height: 12,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete User',
                    splashRadius: 20,
                    onPressed: () async {
                      if (user != null) {
                        await showDeleteDialog(
                          context: context,
                          title: "Delete User",
                          message: "Are you sure you want to delete this user?",
                          onConfirm: () async {
                            // Fix: Use userItemId for deletion if available
                            final String deleteId =
                                user.rawData['userItemId']?.toString() ??
                                user.uid;
                            await context
                                .read<UserScreenViewModel>()
                                .deleteUser(deleteId);
                          },
                        );
                      }
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
      PlutoColumn(
        title: 'User Data',
        field: 'userData',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoRow> _buildPlutoRows(UserScreenViewModel viewModel, bool isMobile) {
    return List.generate(viewModel.paginatedUsers.length, (index) {
      final user = viewModel.paginatedUsers[index];
      final rowNumber = viewModel.pagination.startIndex + index + 1;

      return PlutoRow(
        cells: {
          'no': PlutoCell(value: rowNumber),
          'fullName': PlutoCell(value: user.userName),
          'contact': PlutoCell(value: user.userContact ?? 'N/A'),
          'email': PlutoCell(
            value: (user.userEmail.isEmpty || user.userEmail == 'N/A')
                ? 'No Mail'
                : user.userEmail,
          ),
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
      return "Invalid Date";
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
            const SizedBox(height: 8), // Standardized spacing
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
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 5,
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
                      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                      onPressed: pagination.canGoPrevious
                          ? () {
                              viewModel.goToPreviousPage();
                              _updatePlutoGridRows();
                            }
                          : null,
                    ),
                    Text(
                      '${pagination.currentPage} / ${pagination.totalPages}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: pagination.canGoNext
                          ? () {
                              viewModel.goToNextPage();
                              _updatePlutoGridRows();
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
                          value: pagination.rowsPerPage,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          items: [5, 10, 20, 50]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              viewModel.setRowsPerPage(val);
                              _updatePlutoGridRows();
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
                    int pageNum;
                    if (pagination.totalPages <= 7) {
                      pageNum = index + 1;
                    } else {
                      if (pagination.currentPage <= 4) {
                        pageNum = index + 1;
                      } else if (pagination.currentPage >=
                          pagination.totalPages - 3) {
                        pageNum = pagination.totalPages - 6 + index;
                      } else {
                        pageNum = pagination.currentPage - 3 + index;
                      }
                    }

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
                          value: pagination.rowsPerPage,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          items: [5, 10, 20, 50]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              viewModel.setRowsPerPage(val);
                              _updatePlutoGridRows();
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
