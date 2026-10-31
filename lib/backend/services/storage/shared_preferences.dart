import "package:himig/backend/services/storage/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:shared_preferences/shared_preferences.dart";

class SharedPreferenceStorageService extends StorageService {
  @override
  Future<bool> containsKey(StorageKey key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(key.name);
  }

  @override
  Future<String?> getString(StorageKey key, [String? defaultValue]) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(key.name) ?? defaultValue;
    } catch (error) {
      logger.error(error.toString());
      return null;
    }
  }

  @override
  Future<bool> setString(StorageKey key, String value) async {
    final sp = await SharedPreferences.getInstance();
    return await sp.setString(key.name, value);
  }

  @override
  Future<bool> remove(StorageKey key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.remove(key.name);
  }
}
