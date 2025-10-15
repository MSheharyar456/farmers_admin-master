import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/constants/constants.dart' as appColors;
import 'package:farmers_admin/main.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/screens/ads_image.dart';
import 'package:farmers_admin/screens/post_management/edit_post_screen.dart';
import 'package:farmers_admin/screens/farming_tip/farmingTip.dart';
import 'package:farmers_admin/screens/post_management/post_management_screen.dart';
import 'package:farmers_admin/screens/user_management/user_screen.dart';
import 'package:farmers_admin/screens/working_status/working_status_screen.dart';
import 'package:farmers_admin/user_feedback/user_feedback_screen.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

}

class ContentPage extends StatelessWidget {
  final String title;
  const ContentPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(),

          Container(
            padding: const EdgeInsets.only(right: 30, left: 30, bottom: 30, top: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dashboard / Statistics',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // 🔹 Wrap summary cards inside StreamBuilder
                StreamBuilder<DatabaseEvent>(
                  stream: _dbRef.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green,));
                    }

                    final root = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map,
                    );

                    // --- Users ---
                    int totalUsers = 0;
                    if (root["UsersAuthData"] != null) {
                      final usersData = Map<String, dynamic>.from(root["UsersAuthData"]);
                      totalUsers = usersData.length;
                    }

                    // --- Posts ---
                    int totalPosts = 0;
                    int approvedPosts = 0;
                    int pendingPosts = 0;
                    if (root["productsPostData"] != null) {
                      final postsData = Map<String, dynamic>.from(root["productsPostData"]);
                      totalPosts = postsData.length;

                      postsData.forEach((postId, value) {
                        final postData = Map<String, dynamic>.from(value as Map);
                        final post = Post.fromMap(postId, postData);

                        if (post.postIsApproved) {
                          approvedPosts++;
                        } else {
                          pendingPosts++;
                        }
                      });
                    }

                    final List<Widget> cards = [
                      SummaryCard(
                        title: 'Pending Posts',
                        value: '$pendingPosts',
                        percentage: '',
                        isPositive: true,
                        backgroundColor: appColors.cardBackgroundColor!,

                      ),
                      SummaryCard(
                        title: 'Approved Posts',
                        value: '$approvedPosts',
                        percentage: '',
                        isPositive: false,
                        backgroundColor: appColors.cardBackgroundColor2!,

                      ),
                      SummaryCard(
                        title: 'Total Posts',
                        value: '$totalPosts',
                        percentage: '',
                        isPositive: true,
                        backgroundColor: appColors.cardBackgroundColor!,

                      ),
                      SummaryCard(
                        title: 'Total Users',
                        value: '$totalUsers',
                        percentage: '',
                        isPositive: false,
                        backgroundColor: appColors.cardBackgroundColor2!,

                      ),
                      SummaryCard(
                        title: 'Delete Accounts',
                        value: '0',
                        percentage: '',
                        isPositive: true,
                        backgroundColor: appColors.cardBackgroundColor!,

                      ),
                    ];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const double breakpoint = 900.0;
                        if (constraints.maxWidth < breakpoint) {
                          return Wrap(spacing: 20.0, runSpacing: 20.0, children: cards);
                        } else {
                          return Row(
                            children: cards.map((card) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                  child: card,
                                ),
                              );
                            }).toList(),
                          );
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),
               Container(
                 padding: EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.start,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Pending Requests',
                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                         color: Colors.black,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                     const SizedBox(height: 20),
                     const SizedBox(
                       height: 520,
                       child: RequestsGrid(),
                     ),
                   ],
                 ),
               )
              ],
            ),
          )

        ],
      ),
    );
  }
}




class SummaryCard extends StatelessWidget {
  final String title, value, percentage;
  final bool isPositive;
  final Color backgroundColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
    required this.backgroundColor,
  });

  String _formatTwoDigits(String v) {
    final n = int.tryParse(v);
    if (n != null) return n.toString().padLeft(2, '0');
    return v; // fallback if it's not an integer
  }

  @override
  Widget build(BuildContext context) {
    final Color percentageColor = isPositive ? Colors.green : Colors.red;
    final String arrowIcon = isPositive ? "images/upArrow.svg" : "images/downArrow.svg";

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: backgroundColor,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTwoDigits(value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      percentage,
                      style: TextStyle(
                        color: percentageColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ClipRRect(
                      child: SvgPicture.asset(
                        arrowIcon,
                        semanticsLabel: "Trend Arrow",
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          percentageColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class RequestsGrid extends StatefulWidget {
  const RequestsGrid({super.key});

  @override
  State<RequestsGrid> createState() => _RequestsGridState();
}

class _RequestsGridState extends State<RequestsGrid> {
  late PlutoGridStateManager stateManager;
  late final List<PlutoColumn> columns;
  final double rowHeight = 45;
  final double headerHeight = 50;

  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();

    columns = [
      PlutoColumn(
        title: '#',
        field: 'numbering',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 80,
        minWidth: 50,
      ),
      PlutoColumn(
        title: 'Post Id',
        field: 'id',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Post Title',
        field: 'post_title',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'City',
        field: 'city',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 120,
      ),
      PlutoColumn(
        title: 'Village',
        field: 'village',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        minWidth: 120,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        enableEditingMode: false,
        type: PlutoColumnType.text(),
        minWidth: 115,
        renderer: (rendererContext) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pending',
                style: TextStyle(
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
        width: 120,
        enableSorting: false,
        renderer: (ctx) {
          final postId = ctx.row.cells['postId']?.value;
          final postData = ctx.row.cells['postData']?.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit Button
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
                  tooltip: 'Edit Post',
                  splashRadius: 20,
                  onPressed: () {
                    if (postData != null && postData is Post) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(post: postData),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
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
                  tooltip: 'Delete Post',
                  splashRadius: 20,
                  onPressed: () async {
                    await showDeleteDialog(
                      context: context,
                      title: "Delete Pending Request",
                      message: "Are you sure you want to delete this pending request?",
                      onConfirm: () async {
                        await FirebaseDatabase.instance.ref('productsPostData/$postId').remove();
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
      PlutoColumn(
        title: 'postId',
        field: 'postId',
        type: PlutoColumnType.text(),
        hide: true,
      ),
      PlutoColumn(
        title: 'postData',
        field: 'postData',
        type: PlutoColumnType.text(),
        hide: true,
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('productsPostData').onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.green,));
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/image_farm_nothing_remains.png', height: 150,),
                    const SizedBox(height: 24),
                    const Text(
                      "You're all caught up!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "No Need Pending Approvals.",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!.snapshot.value as Map;
            final postsData = Map<String, dynamic>.from(data);

            final List<PlutoRow> allRows = [];
            int counter = 1;

            postsData.forEach((postId, value) {
              final postMap = Map<dynamic, dynamic>.from(value as Map);
              final post = Post.fromMap(postId, postMap);

              // Only show pending posts
              if (!post.postIsApproved) {
                allRows.add(
                  PlutoRow(
                    cells: {

                      'numbering': PlutoCell(value:  counter.toString()),
                      'id': PlutoCell(value: post.postId ?? ''),
                      'post_title': PlutoCell(value: post.postTitle ?? 'N/A'),
                      'category': PlutoCell(value: post.postCategory ?? 'N/A'),
                      'city': PlutoCell(value: post.postCity ?? 'N/A'),
                      'village': PlutoCell(value: post.postVillage ?? 'N/A'),
                      'status': PlutoCell(value: 'Pending'),
                      'actions': PlutoCell(value: ''),
                      'postId': PlutoCell(value: postId),
                      'postData': PlutoCell(value: post),
                    },
                  ),
                );
                counter++;
              }
            });

            if (allRows.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/image_farm_nothing_remains.png', height: 150,),
                    const SizedBox(height: 24),
                    const Text(
                      "You're all caught up!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "No Need Pending Approvals.",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Pagination logic
            int totalRows = allRows.length;
            int totalPages = (totalRows / _rowsPerPage).ceil();

            int startIndex = (_currentPage - 1) * _rowsPerPage;
            int endIndex = startIndex + _rowsPerPage;
            if (endIndex > totalRows) endIndex = totalRows;

            final paginatedRows = allRows.sublist(startIndex, endIndex);

            final grid = PlutoGrid(
              columns: columns,
              rows: paginatedRows,
              onLoaded: (event) {
                stateManager = event.stateManager;
              },
              configuration: PlutoGridConfiguration(
                columnSize: PlutoGridColumnSizeConfig(
                  autoSizeMode: isSmallScreen
                      ? PlutoAutoSizeMode.none
                      : PlutoAutoSizeMode.scale,
                ),
                style: PlutoGridStyleConfig(
                  rowHeight: 45,
                  columnTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                    enableColumnBorderHorizontal: false,
                  enableCellBorderHorizontal: false,
                  enableColumnBorderVertical: false,

                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid
                SizedBox(
                  height: (paginatedRows.length * rowHeight) + headerHeight,
                  child: isSmallScreen
                      ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: columns.fold<double>(
                        0,
                            (sum, col) => sum + (col.width ?? col.minWidth ?? 120),
                      ),
                      child: grid,
                    ),
                  )
                      : grid,
                ),

                // Pagination
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Prev
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),

                        // Page numbers
                        ...List.generate(totalPages, (index) {
                          final pageNum = index + 1;
                          final isActive = pageNum == _currentPage;
                          return GestureDetector(
                            onTap: () => setState(() => _currentPage = pageNum),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
                                border: Border.all(
                                  color: isActive ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$pageNum",
                                style: TextStyle(
                                  color: isActive ? const Color(0xFF4CAF50) : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),

                        // Next
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),

                        const SizedBox(width: 20),

                        // Rows per page
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
                              value: _rowsPerPage,
                              items: [5, 10, 20, 50]
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text("$e"),
                              ))
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

                        const Text(" / Page"),
                      ],
                    ),
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

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardContent(),
    PostManagementScreen(),
    UserScreen(),

    UserFeedbackScreen(),
    FarmingTipManagementScreen(),
    AdsImageScreen(),
    WorkingStatusManagementScreen(),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close drawer automatically on mobile
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
            backgroundColor: Theme.of(context).extension<AppColors>()!.brandColor,
            title: const Text("Farmers Admin"),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          drawer: isDesktop
              ? null
              : Drawer(
            child: SideMenu(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                SideMenu(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
              Expanded(
                child: Center(
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}