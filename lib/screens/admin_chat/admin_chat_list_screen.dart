import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/viewmodels/user_viewmodel.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:farmers_admin/screens/admin_chat/admin_user_chat_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const ChatListContent(),
    );
  }
}

class ChatListContent extends StatefulWidget {
  const ChatListContent({super.key});

  @override
  State<ChatListContent> createState() => _ChatListContentState();
}

class _ChatListContentState extends State<ChatListContent> {
  late PlutoGridStateManager stateManager;
  final double rowHeight = 40;
  final double headerHeight = 50;

  bool _isGridLoaded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    await context.read<UserScreenViewModel>().loadFromRepository();
    if (mounted && _isGridLoaded) _updatePlutoGridRows();
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
              Text(
                "User Chat Monitoring",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Dashboard / Chat Monitoring",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                      "User Chat Monitoring",
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Dashboard / Chat Monitoring",
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
                  hintText: 'Search user by name, email, or contact...',
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
                      menuMaxHeight: 200,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text("All Status"),
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
                      ElevatedButton(
                        onPressed: () {
                          viewModel.applyFilters();
                          if (_isGridLoaded) _updatePlutoGridRows();
                        },
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
                            viewModel.setSearchQuery('');
                            viewModel.setSelectedStatus(null);
                            viewModel.applyFilters();
                            if (_isGridLoaded) _updatePlutoGridRows();
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
                      hintText: 'Search user by name, email, or contact...',
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
                    ),
                    hint: const Text("Status", style: TextStyle(fontSize: 12)),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 200,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          "All Status",
                          style: TextStyle(fontSize: 12),
                        ),
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
                            viewModel.setSearchQuery('');
                            viewModel.setSelectedStatus(null);
                            viewModel.applyFilters();
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
          );
  }

  Widget _buildUsersList(
    BuildContext context,
    UserScreenViewModel viewModel,
    bool isMobile,
  ) {
    if (viewModel.isLoading) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: LoadingOverlay(text: 'Loading...', showBackdrop: false),
        ),
      );
    }

    if (viewModel.filteredUsers.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        height: 400,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: Colors.grey),
              SizedBox(height: 24),
              Text(
                "No users found",
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
        width: 120,
        minWidth: 120,
        enableEditingMode: false,
        renderer: (ctx) {
          final user = ctx.row.cells['userData']?.value as UserModel?;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 27,
                width: 85,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: InkWell(
                  onTap: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserChatHomeScreen(
                            targetUserId: user.uid,
                            targetUserName: user.userName,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 12,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'View Chats',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          'status': PlutoCell(
            value: user.isVerified ? 'Verified' : 'Unverified',
          ),
          'actions': PlutoCell(value: ''),
          'userData': PlutoCell(value: user),
        },
      );
    });
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
            color: Colors.grey.withValues(alpha: 0.05),
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
                                    style: const TextStyle(fontSize: 12),
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
                                    style: const TextStyle(fontSize: 12),
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
