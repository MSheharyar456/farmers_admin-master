// viewmodels/user_screen_viewmodel.dart
import 'package:farmers_admin/models/pagination_state.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:flutter/material.dart';

class UserScreenViewModel extends ChangeNotifier {
  final UserRepository repository;

  UserScreenViewModel({required this.repository});

  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedScore;
  PaginationState _pagination = PaginationState(
    currentPage: 1,
    rowsPerPage: 10,
    totalRows: 0,
  );

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get searchQuery => _searchQuery;
  String? get selectedStatus => _selectedStatus;
  String? get selectedScore => _selectedScore;
  PaginationState get pagination => _pagination;
  List<UserModel> get filteredUsers => _filteredUsers;
  List<UserModel> get paginatedUsers =>
      _filteredUsers.sublist(_pagination.startIndex, _pagination.endIndex);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Setters
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setSelectedStatus(String? status) {
    _selectedStatus = status;
    _applyFilters(); // 👈 this line makes filtering work immediately
  }

  void setSelectedScore(String? score) {
    _selectedScore = score;
  }

  void setCurrentPage(int page) {
    _pagination = _pagination.copyWith(currentPage: page);
    notifyListeners();
  }

  void setRowsPerPage(int rows) {
    _pagination = _pagination.copyWith(
      rowsPerPage: rows,
      currentPage: 1,
    );
    notifyListeners();
  }

  void goToPreviousPage() {
    if (_pagination.canGoPrevious) {
      setCurrentPage(_pagination.currentPage - 1);
    }
  }

  void goToNextPage() {
    if (_pagination.canGoNext) {
      setCurrentPage(_pagination.currentPage + 1);
    }
  }




  void resetFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _selectedScore = null;
    _pagination = _pagination.copyWith(currentPage: 1);
    _applyFilters();
  }

  void loadUsers(List<UserModel> users) {
    _allUsers = users;
    _pagination = _pagination.copyWith(totalRows: users.length);
    _applyFilters();
  }
  bool _matchesFilters(UserModel user) {
    // 🔍 Search filter
    if (_searchQuery.isNotEmpty) {
      final userName = user.userName.toLowerCase();
      final userEmail = user.userEmail.toLowerCase();
      if (!userName.contains(_searchQuery) && !userEmail.contains(_searchQuery)) {
        return false;
      }
    }

    // ✅ Status filter (handles different possible data formats)
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final isVerified = user.isVerified == true ||
          user.isVerified == 'true' ||
          user.isVerified == '1' ||
          user.isVerified == 1;

      if (_selectedStatus == 'Verified' && !isVerified) return false;
      if (_selectedStatus == 'Unverified' && isVerified) return false;
    }

    // 🧮 Score filter (if used)
    if (_selectedScore != null && _selectedScore!.isNotEmpty) {
      if (user.userScore != _selectedScore) return false;
    }

    return true;
  }


  void _applyFilters() {
    _filteredUsers = _allUsers.where(_matchesFilters).toList();

    // Keep current page valid
    int totalPages =
    (_filteredUsers.length / _pagination.rowsPerPage).ceil();
    int currentPage = _pagination.currentPage;

    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }

    _pagination = _pagination.copyWith(
      totalRows: _filteredUsers.length,
      currentPage: currentPage,
    );

    notifyListeners();
  }

  Future<void> deleteUser(String uid) async {
    try {
      _errorMessage = null;
      await repository.deleteUser(uid);
      _allUsers.removeWhere((user) => user.uid == uid);
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to delete user: ${e.toString()}';
      notifyListeners();
    }
  }
}
