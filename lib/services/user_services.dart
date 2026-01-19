
// ====================
// 2. SERVICE - user_service.dart
// ====================

import 'package:farmers_admin/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> get usersStream =>
      _dbRef.child('usersAuthData').onValue;

  List<UserModel> parseUsersFromSnapshot(Map<String, dynamic> data) {
    final List<UserModel> users = [];
    data.forEach((key, value) {
      final userData = Map<String, dynamic>.from(value as Map);
      users.add(UserModel.fromFirebase(key, userData));
    });
    return users;
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _dbRef.child('usersAuthData/$uid').remove();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
