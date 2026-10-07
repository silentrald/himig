import "package:himig/utils/result.dart";

abstract class RepoClient {
  bool get transaction;

  FutureResult<List<Map<String, dynamic>>> select(
    String sqlString, [
    List<dynamic>? arguments,
  ]);
  FutureResult<int> insert(String table, Map<String, dynamic> values);
  FutureResult<int> update(
    String table,
    Map<String, dynamic> values, [
    Map<String, dynamic>? where,
  ]);
  FutureResult<int> delete(String table, [Map<String, dynamic>? where]);
}

abstract class RepoDatabase {
  RepoClient get client;
  FutureResult<T> startTransaction<T>(
    FutureResult<T> Function(RepoClient) transaction,
  );
}
