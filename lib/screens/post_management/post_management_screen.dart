import 'dart:async';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/screens/post_management/edit_post_screen.dart';
import 'package:farmers_admin/screens/post_management/add_post_screen.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});


  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  late PlutoGridStateManager stateManager;
  late DatabaseReference _dbRef;
  List<Post> _posts = [];
  StreamSubscription<DatabaseEvent>? _postsSubscription;
  bool _isGridLoaded = false;
  bool _isLoading = true;
  final double rowHeight = 45;
  final double headerHeight = 50;

  String _searchQuery = '';
  String? _selectedApproval;
  String? _selectedCategory; // Changed from _selectedGender to _selectedCategory
  int _currentPage = 1;
  int _rowsPerPage = 10;

  List<Post> get _filteredPosts => _posts.where(_matchesFilters).toList();
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
        title: 'Post ID',
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
        width: 200,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 100,
        minWidth: 80,
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
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
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
        renderer: (rendererContext) {
          final postId = rendererContext.row.cells['id']!.value;
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
                  icon: SvgPicture.asset(
                    'images/ic_farm_edit.svg',
                    width: 20,
                    height: 20,
                    color: Colors.blue,
                  ),
                  tooltip: 'Edit Post',
                  splashRadius: 20,
                  onPressed: () {
                    try {
                      final post = _posts.firstWhere((p) => p.postId == postId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(post: post),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: Could not find post with ID $postId')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
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
                      title: "Delete Post",
                      message: "Are you sure you want to delete this post?",
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
    ];
  }

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref().child('productsPostData');
    _selectedApproval = "Approved";
    _listenForPosts();
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
    // Search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final title = post.postTitle?.toLowerCase() ?? '';
      final city = post.postCity?.toLowerCase() ?? '';
      final category = post.postCategory?.toLowerCase() ?? '';
      final village = post.postVillage?.toLowerCase() ?? '';

      if (!title.contains(query) &&
          !city.contains(query) &&
          !village.contains(query) &&
          !category.contains(query)) {
        return false;
      }
    }

    // Approval filter
    if (_selectedApproval != null && _selectedApproval != "All") {
      final approvalStr = post.postIsApproved ? "Approved" : "Pending";
      if (_selectedApproval != approvalStr) return false;
    }

    // ✅ Category filter (fixed)
    if (_selectedCategory != null && _selectedCategory != "All") {
      final postCat = (post.postCategory ?? '').trim().toLowerCase();
      final selectedCat = _selectedCategory!.trim().toLowerCase();
      if (postCat != selectedCat) return false;
    }

    return true;
  }

  void _updatePlutoGridRows() {
    final newRows = <PlutoRow>[];
    int counter = 1; // ✅ Initialize counter

    for (final post in _paginatedPosts) {
      final approvalStatus = post.postIsApproved ? 'Approved' : 'Pending';

      newRows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()), // ✅ Add numbering
            'id': PlutoCell(value: post.postId ?? ''),
            'post_title': PlutoCell(value: post.postTitle ?? ''),
            'category': PlutoCell(value: post.postCategory ?? ''),
            'city': PlutoCell(value: post.postCity ?? ''),
            'village': PlutoCell(value: post.postVillage ?? ''),
            'approvalStatus': PlutoCell(value: approvalStatus),
            'actions': PlutoCell(value: ''),
          },
        ),
      );
      counter++; // ✅ Increment counter
    }

    stateManager.removeAllRows();
    if (newRows.isNotEmpty) stateManager.appendRows(newRows);
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      if (_isGridLoaded) _updatePlutoGridRows();
    });
  }

  // Replace the existing _buildEmptyState() method with these two methods:

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedApproval != null ||
        _selectedCategory != null;

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
            Text(
              "No posts available",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Add your first post to get started",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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

    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/image_farm_nothing_remains.png',
              height: isMobile ? 120 : 150,
            ),
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
              "No posts found",
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
                padding: EdgeInsets.all(isMobile ? 12 : 15),
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
                              'Post',
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
                              "Dashboard / Post's List",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const AddPostScreen()),
                              );
                            },
                            icon: const Icon(Icons.add,
                                color: Colors.white),
                            label: const Text("Add Post",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Post',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Dashboard / Post's List",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const AddPostScreen()),
                            );
                          },
                          icon: const Icon(Icons.add,
                              color: Colors.white),
                          label: const Text("Add Post",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Filters Section - Responsive Layout
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
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
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
                                  horizontal: 20, vertical: 16),
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
                                      fontWeight: FontWeight.bold),
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
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green, width: 2),
                                ),
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Changed Gender filter to Category filter

              Expanded(
              flex: 1,
              child: DropdownButtonFormField2<String>(
                value: _selectedCategory ?? "All",
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder( borderRadius: BorderRadius.circular(8), ),
                  focusedBorder: const OutlineInputBorder( borderSide: BorderSide(color: Colors.green, width: 2), ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),

                hint: const Text("Select Category"),
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All")),
                  DropdownMenuItem(value: "Fruit", child: Text("Fruit")),                    // Changed from "Fruits"
                  DropdownMenuItem(value: "Vegetables", child: Text("Vegetables")),
                  DropdownMenuItem(value: "Jam", child: Text("Jam")),                        // Changed from "Jam & Molasses"
                  DropdownMenuItem(value: "Pomegranate", child: Text("Pomegranate")),
                  DropdownMenuItem(value: "Apples", child: Text("Apples")),
                  DropdownMenuItem(value: "Honey", child: Text("Honey")),
                  DropdownMenuItem(value: "Grain&Seeds", child: Text("Grain&Seeds")),
                  DropdownMenuItem(value: "Fertilizers", child: Text("Fertilizers")),
                  DropdownMenuItem(value: "Animals Feed", child: Text("Animals Feed")),      // Changed from "Animal Feed"
                  DropdownMenuItem(value: "Cheese", child: Text("Cheese")),
                  DropdownMenuItem(value: "Leafy Greens", child: Text("Leafy Greens")),
                  DropdownMenuItem(value: "Olive&Oils", child: Text("Olive&Oils")),          // Changed from "Olives & Oils"
                  DropdownMenuItem(value: "Pesticides", child: Text("Pesticides")),
                  DropdownMenuItem(value: "Agriculture Tools", child: Text("Agriculture Tools")), // Changed from "Agricultural Tools"
                  DropdownMenuItem(value: "Delivery Services", child: Text("Delivery Services")),
                  DropdownMenuItem(value: "Equipments", child: Text("Equipments")),          // Changed from "Equipment"
                  DropdownMenuItem(value: "Land Services", child: Text("Land Services")),
                  DropdownMenuItem(value: "Worker Services", child: Text("Worker Services")),
                  DropdownMenuItem(value: "Irrigation System", child: Text("Irrigation System")), // Changed from "Irrigation Systems"
                  DropdownMenuItem(value: "Live Stock", child: Text("Live Stock")),          // Changed from "Livestock"
                  DropdownMenuItem(value: "Others", child: Text("Others")),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
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

              ),

              SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 20),
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
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid Section
                    SizedBox(
                      child: _isLoading
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.green))
                          : _posts.isEmpty ||
                          (_isGridLoaded && _filteredPosts.isEmpty)
                          ? _buildEmptyState()
                          : Container(

                        color: Colors.white,
                        height: (_paginatedPosts.length * rowHeight) +
                            headerHeight,
                        child: PlutoGrid(
                          columns: _getColumns(),
                          rows: [],
                          onLoaded: (event) {
                            stateManager = event.stateManager;
                            stateManager.setShowColumnFilter(false);
                            setState(() => _isGridLoaded = true);
                            if (_posts.isNotEmpty)
                              _updatePlutoGridRows();
                          },
                          configuration: PlutoGridConfiguration(
                            columnSize:
                            const PlutoGridColumnSizeConfig(
                              autoSizeMode: PlutoAutoSizeMode.scale,
                            ),
                            style: PlutoGridStyleConfig(
                              rowHeight: 45,
                              columnTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold),
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
                                  icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 16,
                                      color: Colors.grey),
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
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey),
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
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _rowsPerPage,
                                      dropdownColor: Colors.white,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18),
                                      items: [5, 10, 20, 50]
                                          .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e'),
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
                        )
                            : Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 16, color: Colors.grey),
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
                                        horizontal: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isActive
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey.shade300,
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(6),
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
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
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
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _rowsPerPage,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18),
                                      items: [5, 10, 20, 50]
                                          .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e'),
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