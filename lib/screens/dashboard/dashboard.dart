import 'package:farmers_admin/common/main_layout.dart';
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
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:farmers_admin/services/permission_helper.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  final String? userType;
  const DashboardScreen({super.key, this.initialIndex = 0, this.userType});

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
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
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Dashboard / Statistics',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Wrap summary cards inside StreamBuilder
                  StreamBuilder<DatabaseEvent>(
                    stream: _dbRef.onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        );
                      }

                      final root = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map,
                      );

                      // --- Users ---
                      int totalUsers = 0;
                      if (root["usersAuthData"] != null) {
                        final usersData = Map<String, dynamic>.from(
                          root["usersAuthData"],
                        );
                        totalUsers = usersData.length;
                      }

                      // --- Posts ---
                      int totalPosts = 0;
                      int approvedPosts = 0;
                      int pendingPosts = 0;
                      int cancelledPosts = 0;
                      int soldPosts = 0;
                      if (root["productsPostData"] != null) {
                        final postsData = Map<String, dynamic>.from(
                          root["productsPostData"],
                        );
                        totalPosts = postsData.length;

                        postsData.forEach((postId, value) {
                          final postData = Map<String, dynamic>.from(
                            value as Map,
                          );
                          final post = Post.fromMap(postId, postData);

                          if (post.postIsSold) {
                            soldPosts++;
                          }
                          if (post.postIsCancelled) {
                            cancelledPosts++;
                          } else if (post.postIsApproved) {
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

                        // SummaryCard(
                        //   title: 'Total Posts',
                        //   value: '$totalPosts',
                        //   percentage: '',
                        //   isPositive: true,
                        //   backgroundColor: appColors.cardBackgroundColor!,
                        //
                        // ),
                        SummaryCard(
                          title: 'Rejected Posts',
                          value: '$cancelledPosts',
                          percentage: '',
                          isPositive: false,
                          backgroundColor: appColors.cardBackgroundColor2!,
                        ),
                        SummaryCard(
                          title: 'Total Users',
                          value: '$totalUsers',
                          percentage: '',
                          isPositive: false,
                          backgroundColor: appColors.cardBackgroundColor!,
                        ),
                        SummaryCard(
                          title: 'Sold Posts',
                          value: '$soldPosts',
                          percentage: '',
                          isPositive: true,
                          backgroundColor: appColors.cardBackgroundColor2!,
                        ),
                        // SummaryCard(
                        //   title: 'Delete Accounts',
                        //   value: '0',
                        //   percentage: '',
                        //   isPositive: true,
                        //   backgroundColor: appColors.cardBackgroundColor!,
                        //
                        // ),
                      ];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          const double breakpoint = 900.0;
                          if (constraints.maxWidth < breakpoint) {
                            return Wrap(
                              spacing: 20.0,
                              runSpacing: 20.0,
                              children: cards,
                            );
                          } else {
                            return Row(
                              children: cards.map((card) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0,
                                    ),
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

                  const SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          child: RequestsGrid(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    final String arrowIcon = isPositive
        ? "images/upArrow.svg"
        : "images/downArrow.svg";

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: backgroundColor,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTwoDigits(value),
                  style: const TextStyle(
                    fontSize: 16,
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
  final double rowHeight = 40;
  final double headerHeight = 50;

  int _currentPage = 1;
  int _rowsPerPage = 5;
  bool _isGridLoaded = false;

  // 🔹 Filter states (applied filters)
  String _searchQuery = '';
  String? _selectedCategory;

  // 🔹 Temporary filter states (not applied until button is clicked)
  String _tempSearchQuery = '';
  String? _tempSelectedCategory;

  // 🔹 Store all pending posts to avoid reloading
  final List<Post> _allPendingPosts = [];
  bool _isInitialLoad = true;

  // Permission states
  bool _canEdit = true;
  bool _canDelete = true;

  // 🔹 Category mapping
  final Map<String, String> _categoryMapping = {
    'All': 'All',
    'Fruits': 'fruits',
    'Vegetables': 'vegetables',
    'Jam': 'jam',
    'Pomegranate': 'pomegranate',
    'Apples': 'apples',
    'Honey': 'honey',
    'Grains & Seeds': 'grain_seeds',
    'Fertilizers': 'fertilizers',
    'Animals Feed': 'animalsFeed',
    'Cheese': 'Cheese',
    'Leafy Green': 'leafyGreen',
    'Olive Oil': 'olive_oil',
    'Pesticides': 'pesticides',
    'Agricultural Tools': 'agriculturalTools',
    'Delivery': 'delivery',
    'Equipments': 'equipments',
    'Land Services': 'landServices',
    'Worker Services': 'workerServices',
    'Irrigation': 'irrigation',
    'Live Stock': 'live_stock',
    'Others': 'others',
  };

  List<Post> get _filteredPosts {
    final filtered = _allPendingPosts.where(_matchesFilters).toList();
    filtered.sort((a, b) => b.postDate.compareTo(a.postDate));
    return filtered;
  }

  int get totalPages => (_filteredPosts.length / _rowsPerPage).ceil();

  List<Post> get _paginatedPosts {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredPosts.sublist(
      startIndex,
      endIndex > _filteredPosts.length ? _filteredPosts.length : endIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = "All";
    _tempSelectedCategory = "All";
    _loadPermissions();
    _initColumns();
  }

  Future<void> _loadPermissions() async {
    final canEdit = await PermissionHelper.canEdit();
    final canDelete = await PermissionHelper.canDelete();
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
        _canDelete = canDelete;
        _initColumns(); // Reinit columns with permissions
      });
    }
  }

  void _initColumns() {
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
        title: 'BarCode',
        field: 'barcode',
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
        minWidth: 110,
        width: 100,
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
          final postData = rendererContext.row.cells['postData']?.value;
          final bool isCancelled = postData is Post && postData.postIsCancelled;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.red : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isCancelled ? 'Rejected' : 'Pending',
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
        width: 125,
        minWidth: 125,
        enableSorting: false,
        renderer: (ctx) {
          final postId = ctx.row.cells['postId']?.value;
          final postData = ctx.row.cells['postData']?.value;
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
                    icon: SvgPicture.asset(
                      'images/ic_farm_edit.svg',
                      width: 15,
                      height: 15,
                      color: Colors.blue,
                    ),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    tooltip: 'Edit Post',
                    splashRadius: 20,
                    onPressed: () {
                      if (postData != null && postData is Post) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPostScreen(
                              post: postData,
                              sourceScreen: 'dashboard',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              if (_canEdit && _canDelete) const SizedBox(width: 5),
              if (_canDelete)
                Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'images/ic_farm_trash.svg',
                      width: 15,
                      height: 15,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete Post',
                    splashRadius: 20,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),

                    onPressed: () async {
                      await showDeleteDialog(
                        context: context,
                        title: "Delete Pending Request",
                        message:
                            "Are you sure you want to delete this pending request?",
                        onConfirm: () async {
                          await FirebaseDatabase.instance
                              .ref('productsPostData/$postId')
                              .remove();
                        },
                      );
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

  bool _matchesFilters(Post post) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final title = post.postTitle.toLowerCase() ?? '';
      final city = post.postCity.toLowerCase() ?? '';
      final category = post.postCategory.toLowerCase() ?? '';
      final village = post.postVillage.toLowerCase() ?? '';
      final barcode = post.postBarCode?.toLowerCase() ?? '';

      if (!title.contains(query) &&
          !city.contains(query) &&
          !village.contains(query) &&
          !category.contains(query) &&
          !barcode.contains(query)) {
        return false;
      }
    }

    if (_selectedCategory != null && _selectedCategory != "All") {
      final postCat = (post.postCategory ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('&', '');

      final selectedDbValue = (_categoryMapping[_selectedCategory] ?? '')
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('&', '');

      if (postCat != selectedDbValue) return false;
    }

    return true;
  }

  void _updatePlutoGridRows() {
    if (!_isGridLoaded) return;

    final newRows = <PlutoRow>[];
    int startIndex = (_currentPage - 1) * _rowsPerPage;
    int counter = startIndex + 1;

    for (final post in _paginatedPosts) {
      newRows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()),
            'barcode': PlutoCell(value: post.postBarCode ?? ''),
            'post_title': PlutoCell(value: post.postTitle ?? 'N/A'),
            'category': PlutoCell(value: post.postCategory ?? 'N/A'),
            'city': PlutoCell(value: post.postCity ?? 'N/A'),
            'village': PlutoCell(value: post.postVillage ?? 'N/A'),
            'status': PlutoCell(
              value: post.postIsCancelled ? 'Rejected' : 'Pending',
            ),
            'actions': PlutoCell(value: ''),
            'postId': PlutoCell(value: post.postId),
            'postData': PlutoCell(value: post),
          },
        ),
      );
      counter++;
    }

    stateManager.removeAllRows();
    if (newRows.isNotEmpty) stateManager.appendRows(newRows);
  }

  // 🔹 Build Filter Section
  Widget _buildFilterSection(bool isMobile, bool isTablet) {
    return isMobile
        ? Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _tempSearchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField2<String>(
                value: _tempSelectedCategory ?? "All",
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                hint: const Text("Select Category"),
                items: _categoryMapping.keys.map((displayName) {
                  return DropdownMenuItem(
                    value: displayName,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _tempSelectedCategory = val;
                  });
                },
                dropdownStyleData: const DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = _tempSearchQuery.toLowerCase();
                      _selectedCategory = _tempSelectedCategory;
                      _currentPage = 1;
                      if (_isGridLoaded) _updatePlutoGridRows();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
          )
        : Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  width: isTablet ? 200 : 300,
                  height: 38,

                  child: TextField(
                    style: const TextStyle(
                      fontSize: 12,
                    ), // 👈 This controls the input text size
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search...',
                      hintStyle: TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _tempSearchQuery = val;
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
                  child: DropdownButtonFormField2<String>(
                    value: _tempSelectedCategory ?? "All",
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    // 👇 ADD THIS
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 20, // 👈 your required icon size
                      iconEnabledColor: Colors.grey,
                      iconDisabledColor: Colors.grey,
                    ),
                    hint: const Text(
                      "Select Category",
                      style: TextStyle(fontSize: 12),
                    ),
                    items: _categoryMapping.keys.map((displayName) {
                      return DropdownMenuItem(
                        value: displayName,
                        child: Text(
                          displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _tempSelectedCategory = val;
                      });
                    },
                    dropdownStyleData: const DropdownStyleData(
                      maxHeight: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = _tempSearchQuery.toLowerCase();
                      _selectedCategory = _tempSelectedCategory;
                      _currentPage = 1;
                      if (_isGridLoaded) _updatePlutoGridRows();
                    });
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = constraints.maxWidth < 600;
        final isMobile = screenWidth < 768;
        final isTablet = screenWidth >= 768 && screenWidth < 1024;

        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('productsPostData').onValue,
          builder: (context, snapshot) {
            if (_isInitialLoad &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/image_farm_nothing_remains.png',
                      height: 150,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "No pending requests available",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Pending requests will appear here",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!.snapshot.value as Map;
            final postsData = Map<String, dynamic>.from(data);

            _allPendingPosts.clear();
            postsData.forEach((postId, value) {
              final postMap = Map<dynamic, dynamic>.from(value as Map);
              final post = Post.fromMap(postId, postMap);
              // Show posts that are not approved (pending) or cancelled (rejected)
              if (!post.postIsApproved || post.postIsCancelled) {
                _allPendingPosts.add(post);
              }
            });

            if (_isInitialLoad) {
              _isInitialLoad = false;
            } else if (_isGridLoaded) {
              // Refresh grid rows when stream data changes and grid is already loaded
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isGridLoaded) {
                  _updatePlutoGridRows();
                }
              });
            }

            if (_filteredPosts.isEmpty) {
              return Column(
                children: [
                  // Show filters even when no results
                  _buildFilterSection(isMobile, isTablet),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Image.asset(
                          'images/image_farm_nothing_remains.png',
                          height: 150,
                        ),
                        const SizedBox(height: 24),
                        if (_allPendingPosts.isEmpty) ...[
                          const Text(
                            "No pending requests available",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Pending requests will appear here",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            "You're all caught up!",
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "No pending requests found matching filters",
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              );
            }

            final actualRowCount = _paginatedPosts.length;
            final gridHeight = (actualRowCount * rowHeight) + headerHeight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Filter Section
                _buildFilterSection(isMobile, isTablet),
                const SizedBox(height: 5),
                // Grid
                SizedBox(
                  height: gridHeight,
                  child: isSmallScreen
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: columns.fold<double>(
                              0,
                              (sum, col) =>
                                  sum + (col.width ?? col.minWidth ?? 120),
                            ),
                            child: PlutoGrid(
                              columns: columns,
                              rows: [],
                              onLoaded: (event) {
                                stateManager = event.stateManager;
                                setState(() => _isGridLoaded = true);
                                _updatePlutoGridRows();
                              },
                              configuration: PlutoGridConfiguration(
                                columnSize: const PlutoGridColumnSizeConfig(
                                  autoSizeMode: PlutoAutoSizeMode.none,
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
                        )
                      : PlutoGrid(
                          columns: columns,
                          rows: [],
                          onLoaded: (event) {
                            stateManager = event.stateManager;
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
                              enableRowColorAnimation: false,
                              oddRowColor: Colors.white,
                              evenRowColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 10),

                // Pagination
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 0,
                    horizontal: isMobile ? 4 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                            ...List.generate(totalPages > 7 ? 7 : totalPages, (
                              index,
                            ) {
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
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
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                "$e",
                                                style: TextStyle(fontSize: 12),
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
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      userType: widget.userType,
      child: const DashboardContent(),
    );
  }
}
