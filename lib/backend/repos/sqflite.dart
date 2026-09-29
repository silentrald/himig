import "package:himig/backend/repos/repo.dart";
import "package:himig/utils/result.dart";
import "package:sqflite/sqflite.dart";

class SqfliteRepoClient extends RepoClient {
  final DatabaseExecutor _client;

  SqfliteRepoClient({required DatabaseExecutor transaction})
    : _client = transaction;

  @override
  Future<Result<List<Map<String, dynamic>>>> select(
    String sqlString, [
    List<dynamic>? arguments,
  ]) async {
    try {
      return Result.ok(await _client.rawQuery(sqlString, arguments));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<int>> insert(String table, Map<String, dynamic> values) async {
    try {
      return Result.ok(await _client.insert(table, values));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<int>> updateById(
    String table,
    String idName,
    dynamic idValue,
    Map<String, dynamic> values,
  ) async {
    try {
      return Result.ok(
        await _client.update(
          table,
          values,
          where: "$idName = ?",
          whereArgs: [idValue],
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<int>> delete(
    String sqlString, [
    List<dynamic>? arguments,
  ]) async {
    try {
      return Result.ok(await _client.rawDelete(sqlString, arguments));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}

class SqfliteRepoDatabase extends RepoDatabase {
  final Database _database;
  final SqfliteRepoClient _client;

  SqfliteRepoDatabase({required Database database})
    : _database = database,
      _client = SqfliteRepoClient(transaction: database);

  @override
  RepoClient get client => _client;

  @override
  Future<Result<T>> startTransaction<T>(
    Future<Result<T>> Function(RepoClient) transaction,
  ) async {
    try {
      return await _database.transaction((database) async {
        final result = await transaction(
          SqfliteRepoClient(transaction: database),
        );
        if (result is ResultError) {
          throw result.error;
        }
        return result;
      });
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
