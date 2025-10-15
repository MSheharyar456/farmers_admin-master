// models/pagination_state.dart
class PaginationState {
  final int currentPage;
  final int rowsPerPage;
  final int totalRows;

  PaginationState({
    required this.currentPage,
    required this.rowsPerPage,
    required this.totalRows,
  });

  int get totalPages => (totalRows / rowsPerPage).ceil();
  int get startIndex => (currentPage - 1) * rowsPerPage;
  int get endIndex {
    int end = startIndex + rowsPerPage;
    return end > totalRows ? totalRows : end;
  }

  bool get canGoPrevious => currentPage > 1;
  bool get canGoNext => currentPage < totalPages;

  PaginationState copyWith({
    int? currentPage,
    int? rowsPerPage,
    int? totalRows,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      totalRows: totalRows ?? this.totalRows,
    );
  }
}