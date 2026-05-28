import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL for the Farmers Hub backend API (same as the Flutter app).
/// Used to sync farming tip of day, users, dashboard, etc. to MySQL when using admin.
///
/// Priority: 1) --dart-define=API_BASE_URL=... at build time
///           2) API_BASE_URL in .env (e.g. for local dev)
///           3) http://localhost:3000
String get apiBaseUrl {
  const dartDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (dartDefine.isNotEmpty) return dartDefine;
  final fromEnv = dotenv.env['API_BASE_URL'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
  return 'https://mahsolek.com';  // Production HTTPS
  
}
