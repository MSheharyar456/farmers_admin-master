// import 'package:flutter/foundation.dart';
// import '../models/post_model.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class PostViewModel extends ChangeNotifier {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Posts');
//
//   // ======================
//   // Private variables
//   // ======================
//   List<Post> _allPosts = [];
//   List<Post> _filteredPosts = [];
//   List<Post> _paginatedPosts = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//
//   int _currentPage = 0;
//   int _rowsPerPage = 10;
//
//   String _selectedCategory = 'All';
//   String _selectedApprovalStatus = 'All';
//   String _searchQuery = '';
//
//   // ======================
//   // Getters
//   // ======================
//   List<Post> get allPosts => _allPosts;
//   List<Post> get filteredPosts => _filteredPosts;
//   List<Post> get paginatedPosts => _paginatedPosts;
//
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;
//
//   int get currentPage => _currentPage;
//   int get totalPages => (_filteredPosts.length / _rowsPerPage).ceil();
//
//   String get selectedCategory => _selectedCategory;
//   String get selectedApprovalStatus => _selectedApprovalStatus;
//
//   // ======================
//   // Init
//   // ======================
//   Future<void> init() async {
//     await fetchPosts();
//   }
//
//   // ======================
//   // Fetch posts
//   // ======================
//   Future<void> fetchPosts() async {
//     _isLoading = true;
//     _errorMessage = '';
//     notifyListeners();
//
//     try {
//       final snapshot = await _dbRef.get();
//       if (snapshot.exists) {
//         final data = Map<String, dynamic>.from(snapshot.value as Map);
//
//         _allPosts = data.entries.map((entry) {
//           final val = Map<String, dynamic>.from(entry.value);
//
//           // Safely parse long timestamp (milliseconds since epoch)
//           DateTime postDate;
//           try {
//             if (val['postDate'] != null) {
//               if (val['postDate'] is int) {
//                 postDate = DateTime.fromMillisecondsSinceEpoch(val['postDate']);
//               } else if (val['postDate'] is double) {
//                 postDate = DateTime.fromMillisecondsSinceEpoch(val['postDate'].toInt());
//               } else if (val['postDate'] is String) {
//                 // Sometimes Firebase saves timestamp as string
//                 postDate = DateTime.fromMillisecondsSinceEpoch(int.parse(val['postDate']));
//               } else {
//                 postDate = DateTime.now();
//               }
//             } else {
//               postDate = DateTime.now();
//             }
//           } catch (_) {
//             postDate = DateTime.now();
//           }
//
//           return Post(
//             postId: entry.key,
//             postTitle: val['postTitle'] ?? '',
//             postCategory: val['postCategory'] ?? '',
//             postCity: val['postCity'] ?? '',
//             postVillage: val['postVillage'] ?? '',
//             postAge: val['postAge'] ?? 0,
//             postGender: val['postGender'] ?? '',
//             postLocation: val['postLocation'] ?? '',
//             postPrice: (val['postPrice'] is num)
//                 ? (val['postPrice'] as num).toDouble()
//                 : double.tryParse(val['postPrice'].toString()) ?? 0.0,
//             postUserVerified: val['postUserVerified'] ?? false,
//             postIsApproved: val['postIsApproved'] ?? false,
//
//             postDate: postDate, // ✅ now included
//           );
//         }).toList();
//       } else {
//         _allPosts = [];
//       }
//
//       applyFilters();
//     } catch (e) {
//       _errorMessage = 'Failed to load posts: $e';
//     }
//
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   // ======================
//   // Filters
//   // ======================
//   void setSearchQuery(String query) {
//     _searchQuery = query.toLowerCase();
//     applyFilters();
//   }
//
//   void setCategoryFilter(String category) {
//     _selectedCategory = category;
//     applyFilters();
//   }
//
//   void setApprovalFilter(String status) {
//     _selectedApprovalStatus = status;
//     applyFilters();
//   }
//
//   void applyFilters() {
//     _filteredPosts = _allPosts.where((post) {
//       final matchesSearch = _searchQuery.isEmpty ||
//           post.postTitle.toLowerCase().contains(_searchQuery) ||
//           post.postCity.toLowerCase().contains(_searchQuery) ||
//           post.postVillage.toLowerCase().contains(_searchQuery);
//
//       final matchesCategory = _selectedCategory == 'All' ||
//           post.postCategory == _selectedCategory;
//
//       final matchesApproval = _selectedApprovalStatus == 'All' ||
//           (_selectedApprovalStatus == 'Approved' && post.postIsApproved) ||
//           (_selectedApprovalStatus == 'Pending' && !post.postIsApproved);
//
//       return matchesSearch && matchesCategory && matchesApproval;
//     }).toList();
//
//     _currentPage = 0;
//     _updatePaginatedPosts();
//     notifyListeners();
//   }
//
//   // ======================
//   // Pagination
//   // ======================
//   void _updatePaginatedPosts() {
//     final start = _currentPage * _rowsPerPage;
//     final end = start + _rowsPerPage;
//     _paginatedPosts = _filteredPosts.sublist(
//       start,
//       end > _filteredPosts.length ? _filteredPosts.length : end,
//     );
//   }
//
//   void nextPage() {
//     if (_currentPage < totalPages - 1) {
//       _currentPage++;
//       _updatePaginatedPosts();
//       notifyListeners();
//     }
//   }
//
//   void previousPage() {
//     if (_currentPage > 0) {
//       _currentPage--;
//       _updatePaginatedPosts();
//       notifyListeners();
//     }
//   }
//
//   // ======================
//   // Delete Post
//   // ======================
//   Future<void> deletePost(String postId) async {
//     try {
//       await _dbRef.child(postId).remove();
//       _allPosts.removeWhere((post) => post.postId == postId);
//       applyFilters();
//     } catch (e) {
//       _errorMessage = 'Failed to delete post: $e';
//       notifyListeners();
//     }
//   }
// }
