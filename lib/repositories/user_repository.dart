// repositories/user_repository.dart
import 'package:farmers_admin/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';

class UserRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<List<UserModel>> getUsersStream() {
    return _database
        .ref('usersAuthData')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <UserModel>[];
      }
      final data = event.snapshot.value as Map;
      return data.entries
          .map((e) => UserModel.fromFirebase(
        e.key,
        Map<String, dynamic>.from(e.value as Map),
      ))
          .toList();
    });
  }

  Future<void> deleteUser(String uid) async {
    await _database.ref('usersAuthData/$uid').remove();
  }
}

