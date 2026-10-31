enum StorageKey { repeatMode }

abstract class StorageService {
  Future<bool> containsKey(StorageKey key);
  Future<String?> getString(StorageKey key, [String? defaultValue]);
  Future<bool> setString(StorageKey key, String value);
  Future<bool> remove(StorageKey key);
}
