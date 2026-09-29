import "package:himig/utils/result.dart";

abstract class RepoClient {
  Future<Result<List<Map<String, dynamic>>>> select(
    String sqlString, [
    List<dynamic>? arguments,
  ]);
  Future<Result<int>> insert(String table, Map<String, dynamic> values);
  Future<Result<int>> updateById(
    String table,
    String idName,
    dynamic idValue,
    Map<String, dynamic> values,
  );
  Future<Result<int>> delete(String sqlString, [List<dynamic>? arguments]);
}

abstract class RepoDatabase {
  RepoClient get client;
  Future<Result<T>> startTransaction<T>(
    Future<Result<T>> Function(RepoClient) transaction,
  );
}
