class DashboardStats {
  final int totalUsers;
  final int pendingRequests;
  final int totalPosts;
  final int approvedPosts;
  final int pendingPosts;
  final int cancelledPosts;
  final int soldPosts;
  final int totalFeedback;
  final int suggestionCount;
  final int complaintCount;
  final int generalCount;
  final int deletedUsersCount;

  DashboardStats({
    required this.totalUsers,
    required this.pendingRequests,
    required this.totalPosts,
    required this.approvedPosts,
    required this.pendingPosts,
    this.cancelledPosts = 0,
    this.soldPosts = 0,
    required this.totalFeedback,
    required this.suggestionCount,
    required this.complaintCount,
    required this.generalCount,
    this.deletedUsersCount = 0,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      pendingRequests: 0,
      totalPosts: 0,
      approvedPosts: 0,
      pendingPosts: 0,
      cancelledPosts: 0,
      soldPosts: 0,
      totalFeedback: 0,
      suggestionCount: 0,
      complaintCount: 0,
      generalCount: 0,
      deletedUsersCount: 0,
    );
  }
}
