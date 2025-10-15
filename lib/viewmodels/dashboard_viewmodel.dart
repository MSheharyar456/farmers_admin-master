
// viewmodels/dashboard_viewmodel.dart
import 'package:farmers_admin/models/dashboard_model.dart';
import 'package:farmers_admin/models/users_feedback_model.dart';
import 'package:farmers_admin/services/firebase_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // State
  DashboardStats _stats = DashboardStats.empty();
  List<FeedbackModel> _feedbackList = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _userNameCache = {};

  // Getters
  DashboardStats get stats => _stats;
  List<FeedbackModel> get feedbackList => _feedbackList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Streams
  Stream<DatabaseEvent> get dataStream => _firebaseService.dataStream;
  Stream<DatabaseEvent> get feedbackStream => _firebaseService.feedbackStream;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Update stats from Firebase data
  void updateStats(Map<String, dynamic> rootData) {
    try {
      _stats = _firebaseService.parseDashboardStats(rootData);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update statistics: $e';
      notifyListeners();
    }
  }

  // Update feedback list
  Future<void> updateFeedbackList(Map<String, dynamic> feedbackData) async {
    try {
      setLoading(true);
      _feedbackList = await _firebaseService.parseFeedbackList(feedbackData);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to update feedback list: $e';
      _feedbackList = [];
    } finally {
      setLoading(false);
    }
  }

  // Delete feedback
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final success = await _firebaseService.deleteFeedback(feedbackId);
      if (success) {
        // Remove from local list
        _feedbackList.removeWhere((feedback) => feedback.id == feedbackId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete feedback: $e';
      notifyListeners();
      return false;
    }
  }

  // Get cached user name
  Future<String> getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    final userName = await _firebaseService.getUserName(userId);
    _userNameCache[userId] = userName;
    return userName;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
