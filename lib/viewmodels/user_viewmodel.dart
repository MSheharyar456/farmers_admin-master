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

  // Pending filter values (not applied until applyFilters() is called)
  String _pendingSearchQuery = '';
  String? _pendingStatus;

  PaginationState _pagination = PaginationState(
    currentPage: 1,
    rowsPerPage: 10,
    totalRows: 0,
  );

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  final bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get searchQuery => _searchQuery;
  String? get selectedStatus => _selectedStatus;
  String get pendingSearchQuery => _pendingSearchQuery;
  String? get pendingStatus => _pendingStatus;
  String? get selectedScore => _selectedScore;
  PaginationState get pagination => _pagination;
  List<UserModel> get filteredUsers => _filteredUsers;
  List<UserModel> get paginatedUsers =>
      _filteredUsers.sublist(_pagination.startIndex, _pagination.endIndex);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSourceDataEmpty => _allUsers.isEmpty;

  // Setters
  void setSearchQuery(String query) {
    _pendingSearchQuery = query;
    notifyListeners(); // Notify to update UI, but don't apply filters
  }

  void setSelectedStatus(String? status) {
    _pendingStatus = status;
    notifyListeners(); // Notify to update UI, but don't apply filters
  }

  // Apply pending filters to active filters
  void applyFilters() {
    _searchQuery = _pendingSearchQuery.toLowerCase();
    _selectedStatus = _pendingStatus;
    _pagination = _pagination.copyWith(
      currentPage: 1,
    ); // Reset to first page when applying filters
    _applyFilters();
  }

  void setSelectedScore(String? score) {
    _selectedScore = score;
  }

  void setCurrentPage(int page) {
    _pagination = _pagination.copyWith(currentPage: page);
    notifyListeners();
  }

  void setRowsPerPage(int rows) {
    _pagination = _pagination.copyWith(rowsPerPage: rows, currentPage: 1);
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
    _pendingSearchQuery = '';
    _pendingStatus = null;
    _pagination = _pagination.copyWith(currentPage: 1);
    _applyFilters();
  }

  void loadUsers(List<UserModel> users) {
    // Sort users by login date before setting to _allUsers
    _allUsers = users
      ..sort((a, b) => b.userLoginDate.compareTo(a.userLoginDate));
    _pagination = _pagination.copyWith(totalRows: users.length);
    _applyFilters();
  }

  bool _matchesFilters(UserModel user) {
    // 🔍 Search filter
    if (_searchQuery.isNotEmpty) {
      final userName = user.userName.toLowerCase();
      final userEmail = user.userEmail.toLowerCase();
      if (!userName.contains(_searchQuery) &&
          !userEmail.contains(_searchQuery)) {
        return false;
      }
    }

    // ✅ Status filter (handles different possible data formats)
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final isVerified =
          user.isVerified == true ||
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
    // First filter the users
    _filteredUsers = _allUsers.where(_matchesFilters).toList();

    // Sort by login date in descending order (newest first)
    _filteredUsers.sort((a, b) => b.userLoginDate.compareTo(a.userLoginDate));

    // Keep current page valid
    int totalPages = (_filteredUsers.length / _pagination.rowsPerPage).ceil();
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
