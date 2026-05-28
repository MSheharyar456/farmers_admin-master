import 'package:farmers_admin/models/dashboard_model.dart';
import 'package:farmers_admin/models/users_feedback_model.dart';
import 'package:farmers_admin/services/admin_dashboard_api_service.dart';
import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._apiService);

  final AdminDashboardApiService _apiService;

  DashboardStats _stats = DashboardStats.empty();
  List<FeedbackModel> _feedbackList = [];
  bool _isLoading = false;
  String? _errorMessage;

  DashboardStats get stats => _stats;
  List<FeedbackModel> get feedbackList => _feedbackList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadStats() async {
    try {
      setLoading(true);
      _errorMessage = null;
      _stats = await _apiService.getStats();
    } catch (e) {
      _errorMessage = 'Failed to load statistics: $e';
      _stats = DashboardStats.empty();
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadFeedback({int limit = 20}) async {
    try {
      _errorMessage = null;
      _feedbackList = await _apiService.getFeedback(limit: limit);
    } catch (e) {
      _errorMessage = 'Failed to load feedback: $e';
      _feedbackList = [];
    }
    notifyListeners();
  }

  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      await _apiService.deleteFeedback(feedbackId);
      _feedbackList.removeWhere((f) => f.id == feedbackId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete feedback: $e';
      notifyListeners();
      return false;
    }
  }
}
