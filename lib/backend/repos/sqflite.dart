import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";
import "package:sqflite/sqflite.dart";

// ignore: implementation_imports
// import "package:sqflite_common_ffi/src/sqflite_ffi_exception.dart";

//final constraintMessageIndex =
//    "SqliteException(2067): while executing statement, UNIQUE constraint failed: "
//        .length;
//final constraintMessageIndex = 76;

class SqfliteRepoClient extends RepoClient {
  final DatabaseExecutor _client;
  final bool _transaction;

  SqfliteRepoClient({required this._client, required this._transaction});

  @override
  bool get transaction => _transaction;

  @override
  FutureResult<List<Map<String, dynamic>>> select(
    String sqlString, [
    List<dynamic>? arguments,
  ]) async {
    try {
      return Result.ok(await _client.rawQuery(sqlString, arguments));
    } on Exception catch (error, stackTrace) {
      return Result.errorWithStackTrace(error, stackTrace);
    }
  }

  @override
  FutureResult<int> insert(String table, Map<String, dynamic> values) async {
    try {
      return Result.ok(await _client.insert(table, values));
      // NOTE: Hide implementation for now, if only needed
      //} on SqfliteFfiException catch (error, stackTrace) {
      //  if (!error.isUniqueConstraintError()) {
      //    return Result.errorWithStackTrace(error, stackTrace);
      //  }
      //
      //  final constraintInfo = error.message!
      //      .substring(
      //        constraintMessageIndex,
      //        error.message!.indexOf(",", constraintMessageIndex),
      //      )
      //      .split(".");
      //  return Result.errorWithStackTrace(
      //    TODO: Replace the error here
      //    ProjectError(
      //      .repoUniqueConstraint,
      //      arguments: {"table": constraintInfo[0], "name": constraintInfo[1]},
      //    ),
      //    stackTrace,
      //  );
    } on Exception catch (error, stackTrace) {
      return Result.errorWithStackTrace(error, stackTrace);
    }
  }

  @override
  FutureResult<int> update(
    String table,
    Map<String, dynamic> values, [
    Map<String, dynamic>? where,
  ]) async {
    try {
      return Result.ok(
        await _client.update(
          table,
          values,
          where: where?.keys.map((e) => "$e = ?").join(" AND "),
          whereArgs: where?.values.toList(),
        ),
      );
    } on Exception catch (error, stackTrace) {
      return Result.errorWithStackTrace(error, stackTrace);
    }
  }

  @override
  FutureResult<int> delete(String table, [Map<String, dynamic>? where]) async {
    try {
      return Result.ok(
        await _client.delete(
          table,
          where: where?.keys.map((e) => "$e = ?").join(" AND "),
          whereArgs: where?.values.toList(),
        ),
      );
    } on Exception catch (error, stackTrace) {
      return Result.errorWithStackTrace(error, stackTrace);
    }
  }
}

class SqfliteRepoDatabase extends RepoDatabase {
  final Database _database;
  final SqfliteRepoClient _client;

  SqfliteRepoDatabase({required Database database})
    : _database = database,
      _client = SqfliteRepoClient(client: database, transaction: false);

  @override
  RepoClient get client => _client;

  @override
  FutureResult<T> startTransaction<T>(
    FutureResult<T> Function(RepoClient) transaction,
  ) async {
    try {
      return await _database.transaction((database) async {
        final result = await transaction(
          SqfliteRepoClient(client: database, transaction: true),
        );
        if (result is ResultError) {
          throw result;
        }
        return result;
      });
    } on ResultError catch (error) {
      return error.toError();
    } on Exception catch (error, stackTrace) {
      return Result.errorWithStackTrace(error, stackTrace);
    }
  }
}

/* === Helper Functions === */

FutureResult<int> deleteAllAndResetTable(
  RepoClient client,
  String tableName,
) async {
  assert(
    client.transaction,
    "$tableName should be deleted with a client transaction",
  );

  final countResult = await client.delete(tableName);
  if (countResult is ResultError) {
    return countResult;
  }

  final result = await client.update(
    "sqlite_sequence",
    {"seq": 0},
    {"name": tableName},
  );
  if (result is ResultError) {
    return result;
  }

  return countResult;
}
