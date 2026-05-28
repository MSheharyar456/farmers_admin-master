// services/firebase_services.dart
//
// Migrated to backend: dashboard stats, feedback list/delete, and getUserName
// are now provided by AdminDashboardApiService and GET/DELETE /admin/feedback.
// This file is kept as a stub for reference. Admin chat (if any) uses
// Firebase elsewhere (e.g. admin_chats / chatRooms), not this service.

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
}
