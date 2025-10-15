



// screens/user_screen.dart
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:farmers_admin/screens/user_management/add_user_screen.dart';
import 'package:farmers_admin/screens/user_management/edit_user_screen.dart';
import 'package:farmers_admin/viewmodels/user_viewmodel.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late PlutoGridStateManager stateManager;
  final double rowHeight = 45;
  final double headerHeight = 50;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ChangeNotifierProvider(
      create: (_) => UserScreenViewModel(
        repository: UserRepository(),
      ),
      child: Scaffold(
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Consumer<UserScreenViewModel>(
                builder: (context, viewModel, _) {
                  return SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 15),
                      child: Column(
                        children: [
                          _buildHeader(context, isMobile),
                          const SizedBox(height: 20),
                          _buildFilters(context, viewModel, isMobile),
                          const SizedBox(height: 20),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Dashboard / Customer's List",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCustomerScreen(),
                ),
              ).then((_) => setState(() {}));
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Customer",
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
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
                "Customer's List",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Dashboard / Customer's List",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddCustomerScreen(),
              ),
            ).then((_) => setState(() {}));
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label:
          const Text("Add Customer", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(
      BuildContext context, UserScreenViewModel viewModel, bool isMobile) {
    return isMobile
        ? Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (val) => viewModel.setSearchQuery(val),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: viewModel.selectedStatus,

                decoration: InputDecoration(
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text("Status"),
                dropdownColor: Colors.white, // 👈 makes dropdown menu white
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text("All")),
                  DropdownMenuItem<String?>(
                      value: "Verfied", child: Text("Verfied")),
                  DropdownMenuItem<String?>(
                      value: "UnVerified", child: Text("UnVerified")),
                ],
                onChanged: (val) => viewModel.setSelectedStatus(val),

              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: SvgPicture.asset(
                'images/ic_farm_filter.svg',
                height: 20,
                width: 20,
                color: Colors.white,
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
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) => viewModel.setSearchQuery(val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String?>(
            value: viewModel.selectedStatus,
            decoration: InputDecoration(
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            hint: const Text("Status"),
            dropdownColor: Colors.white, // 👈 makes dropdown menu white
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text("All")),
              DropdownMenuItem<String?>(value: "Verified", child: Text("Verified")),
              DropdownMenuItem<String?>(value: "Unverified", child: Text("Unverified")),
            ],

            onChanged: (val) => viewModel.setSelectedStatus(val),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
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
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList(
      BuildContext context, UserScreenViewModel viewModel, bool isMobile) {
    return StreamBuilder<List<UserModel>>(
      stream: UserRepository().getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isMobile, "No users found");
        }

        viewModel.loadUsers(snapshot.data!);

        if (viewModel.filteredUsers.isEmpty) {
          return _buildEmptyState(isMobile, "No users found matching your filters.");
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
                },
                configuration: PlutoGridConfiguration(
                  columnSize: const PlutoGridColumnSizeConfig(
                    autoSizeMode: PlutoAutoSizeMode.scale,
                  ),
                  style: PlutoGridStyleConfig(
                    rowHeight: 45,
                    columnTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            _buildPaginationFooter(context, viewModel, isMobile),
          ],
        );
      },
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
          Color statusColor;
          switch (value) {
            case 'Verified':
              statusColor = Colors.green;
              break;
            case 'Unverified':
              statusColor = Colors.orange;
              break;
            default:
              statusColor = Colors.grey;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
        width: isMobile ? 80 : 150,
        minWidth: 80,
        enableEditingMode: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (ctx) {
          final user = ctx.row.cells['userData']?.value as UserModel?;
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
                  padding: EdgeInsets.zero,
                  icon: SvgPicture.asset(
                    'images/ic_farm_edit.svg',
                    width: 18,
                    height: 18,
                    color: Colors.blue,
                  ),
                  tooltip: 'Edit User',
                  splashRadius: 20,
                  onPressed: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditUserScreen(user: user.toMap()),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  },
                ),
              ),
              if (!isMobile) const SizedBox(width: 8),
              if (!isMobile)
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_trash.svg',
                      width: 18,
                      height: 18,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete User',
                    splashRadius: 20,
                      onPressed: () async {
                        if (user != null) {
                          final viewModel = context.read<UserScreenViewModel>(); // 👈 get it here

                          await showDeleteDialog(
                            context: context,
                            title: "Delete User",
                            message: "Are you sure you want to delete this user?",
                            onConfirm: () async {
                              await viewModel.deleteUser(user.uid);
                              if (!context.mounted) return;
                              // no need to show another snackbar, your dialog already does it
                            },
                          );
                        }
                      }
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
    return List.generate(
      viewModel.paginatedUsers.length,
          (index) {
        final user = viewModel.paginatedUsers[index];
        final rowNumber = viewModel.pagination.startIndex + index + 1;

        return PlutoRow(
          cells: {
            'no': PlutoCell(value: rowNumber),
            'fullName': PlutoCell(value: user.userName),
            'email': PlutoCell(value: user.userEmail),
            'dob': PlutoCell(value: user.dob),
            'status': PlutoCell(value: user.isVerified ? 'Verified' : 'Unverified'),
            'actions': PlutoCell(value: ''),
            'userData': PlutoCell(value: user),
          },
        );

          },
    );
  }

  Widget _buildEmptyState(bool isMobile, String message) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/image_farm_nothing_remains.png',
                height: isMobile ? 120 : 150),
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
              message,
              textAlign: TextAlign.center,
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

  Widget _buildPaginationFooter(BuildContext context,
      UserScreenViewModel viewModel, bool isMobile) {
    final pagination = viewModel.pagination;

    return Container(
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
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                onPressed: pagination.canGoPrevious
                    ? () => viewModel.goToPreviousPage()
                    : null,
              ),
              ...List.generate(
                pagination.totalPages > 5 ? 5 : pagination.totalPages,
                    (index) {
                  int pageNum = index + 1;
                  bool isActive = pageNum == pagination.currentPage;
                  return GestureDetector(
                    onTap: () => viewModel.setCurrentPage(pageNum),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE8F5E9)
                            : Colors.white,
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(6),
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
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: pagination.canGoNext
                    ? () => viewModel.goToNextPage()
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
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pagination.rowsPerPage,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: [5, 10, 20, 50]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        viewModel.setRowsPerPage(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text("/ Page", style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: Colors.grey),
            onPressed: pagination.canGoPrevious
                ? () => viewModel.goToPreviousPage()
                : null,
          ),
          ...List.generate(pagination.totalPages, (index) {
            int pageNum = index + 1;
            bool isActive = pageNum == pagination.currentPage;
            return GestureDetector(
              onTap: () => viewModel.setCurrentPage(pageNum),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE8F5E9)
                      : Colors.white,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(6),
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
          }),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onPressed: pagination.canGoNext
                ? () => viewModel.goToNextPage()
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
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pagination.rowsPerPage,
                    icon:
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: [5, 10, 20, 50]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        viewModel.setRowsPerPage(val);
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
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String uid) async {
    final viewModel =
    Provider.of<UserScreenViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  "Are you sure want to delete this user?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Yes, I'm sure",
                          style: TextStyle(color: Colors.white)),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("No, cancel",
                          style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await viewModel.deleteUser(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    }
  }
}