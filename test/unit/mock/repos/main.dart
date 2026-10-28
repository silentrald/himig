import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class MockRepoClient extends RepoClient {
  final bool _transaction;

  MockRepoClient({this._transaction = false});

  @override
  bool get transaction => _transaction;

  @override
  FutureResult<List<Map<String, dynamic>>> select(
    String sqlString, [
    List<dynamic>? arguments,
  ]) async => Result.ok(List.of([]));

  @override
  FutureResult<int> insert(String table, Map<String, dynamic> values) async =>
      Result.ok(1);

  @override
  FutureResult<int> update(
    String table,
    Map<String, dynamic> values, [
    Map<String, dynamic>? where,
  ]) async => Result.ok(1);

  @override
  FutureResult<int> delete(String table, [Map<String, dynamic>? where]) async =>
      Result.ok(1);
}

class MockRepoDatabase extends RepoDatabase {
  final _client = MockRepoClient();

  @override
  RepoClient get client => _client;

  @override
  FutureResult<T> startTransaction<T>(
    FutureResult<T> Function(RepoClient) transaction,
  ) => transaction.call(MockRepoClient(transaction: true));
}
