import 'package:firebase_database/firebase_database.dart';

class CommissionRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> deleteCommission(String itemId) async {
    await _database.ref('commissionsData/$itemId').remove();
  }
}
