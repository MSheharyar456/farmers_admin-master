// services/firebase_service.dart
import 'package:farmers_admin/models/dashboard_model.dart';
import 'package:farmers_admin/models/users_feedback_model.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Stream for all data
  Stream<DatabaseEvent> get dataStream => _dbRef.onValue;

  // Stream for feedback data
  Stream<DatabaseEvent> get feedbackStream => _dbRef.child('userFeedback').onValue;

  // Get user name by ID
  Future<String> getUserName(String userId) async {
    try {
      final snapshot = await _dbRef.child('UsersAuthData/$userId/userName').get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
    return 'Unknown User';
  }

  // Delete feedback
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      await _dbRef.child('userFeedback/$feedbackId').remove();
      return true;
    } catch (e) {
      print('Error deleting feedback: $e');
      return false;
    }
  }

  // Parse dashboard stats from root data
  DashboardStats parseDashboardStats(Map<String, dynamic> root) {
    // Users calculation
    int totalUsers = 0;
    int pendingRequests = 0;
    if (root["UsersAuthData"] != null) {
      final usersData = Map<String, dynamic>.from(root["UsersAuthData"]);
      totalUsers = usersData.length;

      usersData.forEach((uid, value) {
        final user = Map<String, dynamic>.from(value as Map);
        final status = (user['userStatus'] as String?) ?? "Inactive";
        final verified = user['userIsVerified'] as bool? ?? false;

        if (status == "Inactive" || status == "Deactivated" || !verified) {
          pendingRequests++;
        }
      });
    }

    // Posts calculation
    int totalPosts = 0;
    int approvedPosts = 0;
    int pendingPosts = 0;
    if (root["productsPostData"] != null) {
      final postsData = Map<String, dynamic>.from(root["productsPostData"]);
      totalPosts = postsData.length;

      postsData.forEach((postId, value) {
        final postData = Map<String, dynamic>.from(value as Map);
        final isApproved = postData['postIsApproved'] as bool? ?? false;

        if (isApproved) {
          approvedPosts++;
        } else {
          pendingPosts++;
        }
      });
    }

    // Feedback calculation
    int totalFeedback = 0;
    int suggestionCount = 0;
    int complaintCount = 0;
    int generalCount = 0;
    if (root["userFeedback"] != null) {
      final feedbackData = Map<String, dynamic>.from(root["userFeedback"]);
      totalFeedback = feedbackData.length;

      feedbackData.forEach((feedbackId, value) {
        final feedback = Map<String, dynamic>.from(value as Map);
        final type = feedback['type']?.toString() ?? 'General';

        switch (type) {
          case 'Suggestion':
            suggestionCount++;
            break;
          case 'Complaint':
            complaintCount++;
            break;
          case 'General':
            generalCount++;
            break;
        }
      });
    }

    return DashboardStats(
      totalUsers: totalUsers,
      pendingRequests: pendingRequests,
      totalPosts: totalPosts,
      approvedPosts: approvedPosts,
      pendingPosts: pendingPosts,
      totalFeedback: totalFeedback,
      suggestionCount: suggestionCount,
      complaintCount: complaintCount,
      generalCount: generalCount,
    );
  }

  // Parse feedback list from data
  Future<List<FeedbackModel>> parseFeedbackList(Map<String, dynamic> feedbackData) async {
    final List<FeedbackModel> feedbackList = [];

    // Convert to list and sort by timestamp (newest first)
    final feedbackEntries = feedbackData.entries.toList();
    feedbackEntries.sort((a, b) {
      final timestampA = (a.value as Map)['timestamp'] as int? ?? 0;
      final timestampB = (b.value as Map)['timestamp'] as int? ?? 0;
      return timestampB.compareTo(timestampA); // newest first
    });

    // Take only the latest 20 feedback entries for dashboard
    final recentEntries = feedbackEntries.take(20);

    for (final entry in recentEntries) {
      final feedbackId = entry.key;
      final feedback = Map<String, dynamic>.from(entry.value as Map);

      // Get user name
      final userId = feedback['userId'] ?? '';
      final userName = await getUserName(userId);
      feedback['userName'] = userName;

      feedbackList.add(FeedbackModel.fromMap(feedbackId, feedback));
    }

    return feedbackList;
  }
}