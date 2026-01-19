import 'dart:async';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/screens/post_management/edit_post_screen.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:farmers_admin/services/permission_helper.dart';

class SoldPostsScreen extends StatefulWidget {
  const SoldPostsScreen({super.key});

  @override
  State<SoldPostsScreen> createState() => _SoldPostsScreenState();
}

class _SoldPostsScreenState extends State<SoldPostsScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const SoldPostsContent(),
    );
  }
}

class SoldPostsContent extends StatefulWidget {
  const SoldPostsContent({super.key});

  @override
  State<SoldPostsContent> createState() => _SoldPostsContentState();
}

class _SoldPostsContentState extends State<SoldPostsContent> {
  late PlutoGridStateManager stateManager;
  late DatabaseReference _dbRef;
  List<Post> _posts = [];
  StreamSubscription<DatabaseEvent>? _postsSubscription;
  bool _isGridLoaded = false;
  bool _isLoading = true;
  final double rowHeight = 40;
  final double headerHeight = 50;

  String _searchQuery = '';
  String? _selectedApproval;
  String? _selectedCategory;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Permission states
  bool _canEdit = true;
  bool _canDelete = true;

  // Helper method to format display text
  String _formatDisplayText(String text) {
    if (text.isEmpty) return text;

    // Handle specific cases
    final specialCases = {
      'fruits': 'Fruits',
      'vegetables': 'Vegetables',
      'jam': 'Jam',
      'pomegranate': 'Pomegranate',
      'apples': 'Apples',
      'honey': 'Honey',
      'grain_seeds': 'Grains & Seeds',
      'fertilizers': 'Fertilizers',
      'animalsFeed': 'Animals Feed',
      'Cheese': 'Cheese',
      'leafyGreen': 'Leafy Green',
      'olive_oil': 'Olive Oil',
      'pesticides': 'Pesticides',
      'agriculturalTools': 'Agricultural Tools',
      'delivery': 'Delivery',
      'equipments': 'Equipments',
      'landServices': 'Land Services',
      'workerServices': 'Worker Services',
      'irrigation': 'Irrigation',
      'live_stock': 'Live Stock',
      'others': 'Others',
    };

    // Check if it's a special case
    if (specialCases.containsKey(text)) {
      return specialCases[text]!;
    }

    // Convert camelCase or snake_case to Title Case
    String result = text
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .trim();

    // Capitalize first letter of each word
    return result
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // Category mapping: Display Name -> Database Value
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
    // First filter the posts - Only sold posts
    final filtered = _posts
        .where((post) => post.postIsSold == true)
        .where(_matchesFilters)
        .toList();
    // Then sort by postDate in descending order (newest first)
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
        width: 200,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final rawValue = ctx.cell.value?.toString() ?? '';
          final formattedValue = _formatDisplayText(rawValue);
          return Text(
            formattedValue,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'City',
        field: 'city',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Village',
        field: 'village',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Approval Status',
        field: 'approvalStatus',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final value = ctx.cell.value?.toString() ?? 'Pending';
          final isApproved = value == 'Approved';
          final statusColor = isApproved ? Colors.green : Colors.orange;
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
              Text(
                value,
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
        enableEditingMode: false,
        width: 125,
        minWidth: 125,
        renderer: (rendererContext) {
          final postId = rendererContext.row.cells['id']!.value;
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
                    tooltip: 'Edit Post',
                    splashRadius: 20,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    onPressed: () {
                      try {
                        final post = _posts.firstWhere(
                          (p) => p.postId == postId,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPostScreen(
                              post: post,
                              sourceScreen: 'sold_posts',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: Could not find post with ID $postId',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              if (_canEdit && _canDelete) const SizedBox(width: 8),
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
                        title: "Delete Post",
                        message: "Are you sure you want to delete this post?",
                        onConfirm: () async {
                          await FirebaseDatabase.instance
                              .ref('productsPostData/$postId')
                              .remove();
                          setState(() {});
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
    ];
  }

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref().child('productsPostData');
    _selectedApproval = "Approved";
    _selectedCategory = "All"; // Initialize category
    _loadPermissions();
    _listenForPosts();
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

  void _listenForPosts() {
    _postsSubscription = _dbRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return;

      if (_isLoading) {
        setState(() => _isLoading = false);
      }

      if (event.snapshot.value != null) {
        final rawData = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Post> loadedPosts = [];
        rawData.forEach((key, value) {
          if (value is Map) {
            final postMap = Map<dynamic, dynamic>.from(value);
            loadedPosts.add(Post.fromMap(key, postMap));
          }
        });

        // Sort posts by date before setting state
        loadedPosts.sort((a, b) => b.postDate.compareTo(a.postDate));

        setState(() {
          _posts = loadedPosts;
        });
        if (_isGridLoaded) _updatePlutoGridRows();
      } else {
        setState(() => _posts = []);
        if (_isGridLoaded) _updatePlutoGridRows();
      }
    });
  }

  bool _matchesFilters(Post post) {
    // Only show sold posts - this check is already done in _filteredPosts getter
    // But we keep it here for consistency
    if (!post.postIsSold) return false;

    // Search query filter
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

    // Approval filter
    if (_selectedApproval != null && _selectedApproval != "All") {
      final approvalStr = post.postIsApproved ? "Approved" : "Pending";
      if (_selectedApproval != approvalStr) return false;
    }

    // Category filter - MORE ROBUST with normalization
    if (_selectedCategory != null && _selectedCategory != "All") {
      // Normalize post category
      final postCat = (post.postCategory ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('&', '');

      // Normalize selected category
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
    final newRows = <PlutoRow>[];

    // Calculate the starting number based on current page and rows per page
    int startingNumber = ((_currentPage - 1) * _rowsPerPage) + 1;
    int counter = startingNumber;

    for (final post in _paginatedPosts) {
      final approvalStatus = post.postIsApproved ? 'Approved' : 'Pending';

      newRows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()),
            'id': PlutoCell(value: post.postId ?? ''),
            'barcode': PlutoCell(value: post.postBarCode ?? ''),
            'post_title': PlutoCell(value: post.postTitle ?? ''),
            'category': PlutoCell(
              value: post.postCategory ?? '',
            ), // Keep raw value
            'city': PlutoCell(value: post.postCity ?? ''),
            'village': PlutoCell(value: post.postVillage ?? ''),
            'approvalStatus': PlutoCell(value: approvalStatus),
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
    _postsSubscription?.cancel();
    super.dispose();
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchQuery.isNotEmpty ||
        (_selectedApproval != null && _selectedApproval != "All") ||
        (_selectedCategory != null && _selectedCategory != "All");

    // If filters are applied and no results, show compact version
    if (hasFilters && _posts.isNotEmpty) {
      return _buildNoResultsState();
    }

    // If no posts at all, show full empty state
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
            const Text(
              "No sold posts available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Sold posts will appear here",
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
            Image.asset('images/image_farm_nothing_remains.png', height: 150),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "No sold posts found",
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
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 40,
                  vertical: isMobile ? 12 : 20,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sold Posts',
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
                                    "Dashboard / Sold Posts",
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
                                ],
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(width: double.infinity),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sold Posts',
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
                                    "Dashboard / Sold Posts",
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
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 15),

                    // Filters Section - Responsive Layout with REAL-TIME FILTERING
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
                                    _searchQuery = val.toLowerCase();
                                    _currentPage = 1; // Reset to first page
                                    if (_isGridLoaded) _updatePlutoGridRows();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField2<String>(
                                value: _selectedCategory ?? "All",
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
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
                                hint: const Text(
                                  "Select Category",
                                  style: TextStyle(fontSize: 12),
                                ),
                                items: _categoryMapping.keys.map((displayName) {
                                  return DropdownMenuItem(
                                    value: displayName,
                                    child: Text(displayName),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategory = val;
                                    _currentPage = 1; // Reset to first page
                                    if (_isGridLoaded) _updatePlutoGridRows();
                                  });
                                },
                                dropdownStyleData: const DropdownStyleData(
                                  maxHeight: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: double.infinity),
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
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Search...',
                                      hintStyle: TextStyle(fontSize: 12),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 0,
                                          ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val.toLowerCase();
                                        _currentPage = 1; // Reset to first page
                                        if (_isGridLoaded)
                                          _updatePlutoGridRows();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 38, //
                                  child: DropdownButtonFormField2<String>(
                                    value: _selectedCategory ?? "All",
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 10,
                                          ),
                                    ),
                                    // 👇 ADD THIS
                                    iconStyleData: const IconStyleData(
                                      icon: Icon(Icons.arrow_drop_down),
                                      iconSize:
                                          20, // 👈 your required icon size
                                      iconEnabledColor: Colors.grey,
                                      iconDisabledColor: Colors.grey,
                                    ),
                                    hint: const Text(
                                      "Select Category",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    items: _categoryMapping.keys.map((
                                      displayName,
                                    ) {
                                      return DropdownMenuItem(
                                        value: displayName,
                                        child: Text(
                                          displayName,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCategory = val;
                                        _currentPage = 1; // Reset to first page
                                        if (_isGridLoaded)
                                          _updatePlutoGridRows();
                                      });
                                    },

                                    dropdownStyleData: const DropdownStyleData(
                                      maxHeight: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Filters are applied in real-time, button can be removed or used for other actions
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
                              // REMOVED THE "APPLY FILTERS" BUTTON - No longer needed!
                            ],
                          ),
                    const SizedBox(height: 10),

                    // Grid Section
                    SizedBox(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            )
                          : _posts.isEmpty || _filteredPosts.isEmpty
                          ? _buildEmptyState()
                          : Container(
                              color: Colors.white,
                              height:
                                  (_paginatedPosts.length * rowHeight) +
                                  headerHeight,
                              child: PlutoGrid(
                                columns: _getColumns(),
                                rows: [],
                                onLoaded: (event) {
                                  stateManager = event.stateManager;
                                  stateManager.setShowColumnFilter(false);
                                  setState(() => _isGridLoaded = true);
                                  if (_posts.isNotEmpty) _updatePlutoGridRows();
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
                                    cellTextStyle: const TextStyle(
                                      fontSize: 12,
                                    ),
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
                    if (!_isLoading && _filteredPosts.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 5,
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
                                          horizontal: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
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
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
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
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
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
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
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
                                                      '$e',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
