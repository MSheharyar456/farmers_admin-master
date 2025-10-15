class DashboardStats {
  final int totalUsers;
  final int pendingRequests;
  final int totalPosts;
  final int approvedPosts;
  final int pendingPosts;
  final int totalFeedback;
  final int suggestionCount;
  final int complaintCount;
  final int generalCount;

  DashboardStats({
    required this.totalUsers,
    required this.pendingRequests,
    required this.totalPosts,
    required this.approvedPosts,
    required this.pendingPosts,
    required this.totalFeedback,
    required this.suggestionCount,
    required this.complaintCount,
    required this.generalCount,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      pendingRequests: 0,
      totalPosts: 0,
      approvedPosts: 0,
      pendingPosts: 0,
      totalFeedback: 0,
      suggestionCount: 0,
      complaintCount: 0,
      generalCount: 0,
    );
  }
}
