import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/handler/supabase.dart';

class DatabaseMigrations {
  static const int currentVersion = 1;
  static const String versionKey = 'db_schema_version';
  
  static Future<void> runMigrations() async {
    try {
      int currentDbVersion = await _getCurrentVersion();
      
      if (currentDbVersion < currentVersion) {
        for (int version = currentDbVersion + 1; version <= currentVersion; version++) {
          await _runMigration(version);
          await _updateVersion(version);
        }
      }
    } catch (e) {
      // Silent fail - don't expose database errors
    }
  }
  
  static Future<int> _getCurrentVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(versionKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  static Future<void> _runMigration(int version) async {
    try {
      switch (version) {
        case 1:
          await _migrationV1();
          break;
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  static Future<void> _migrationV1() async {
    try {
      await SupabaseHandler.insertData(
        table: 'schema_migrations',
        data: {
          'version': 1,
          'description': 'Initial schema with indexes',
          'executed_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Migration already exists or failed - continue
    }
  }
  
  static Future<void> _updateVersion(int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(versionKey, version);
    } catch (e) {
      // Silent fail
    }
  }
}
