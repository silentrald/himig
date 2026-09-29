enum StorageKey { none }

abstract class StorageService {
  Future<bool> containsKey(StorageKey key);
  Future<String?> getString(StorageKey key);
  Future<bool> setString(StorageKey key, String value);
  Future<bool> remove(StorageKey key);
}
