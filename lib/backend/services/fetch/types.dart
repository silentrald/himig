import "package:himig/utils/result.dart";

class FetchRequest {
  final Uri uri;
  Map<String, String> headers = {};
  Map<String, Object> data = {};

  FetchRequest(this.uri, {this.headers = const {}, this.data = const {}});
}

class FetchResponse<T> {
  final int status;
  T? data;
  Map<String, String> headers = {};

  FetchResponse(this.status, {this.data});
}

abstract class FetchService {
  //Future<Result<FetchResponse<T>>> get<T>(FetchRequest request);
  Future<Result<FetchResponse<Map<String, dynamic>>>> getJson(
    FetchRequest request,
  );
  Future<Result<FetchResponse<T>>> download<T>(
    FetchRequest request,
    String filepath, {
    void Function(int count, int total)? progress,
  });
  Future<Result<FetchResponse<T>>> post<T>(FetchRequest request);
}
