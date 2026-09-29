import "package:dio/dio.dart";
import "package:himig/backend/services/fetch/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class DioFetchService extends FetchService {
  final _dio = Dio();

  @override
  Future<Result<FetchResponse<Map<String, dynamic>>>> getJson(
    FetchRequest request,
  ) async {
    try {
      logger.debug("GET ${request.uri.toString()}");
      final dioResponse = await _dio.getUri(request.uri);
      final response = FetchResponse<Map<String, dynamic>>(
        dioResponse.statusCode!,
      );
      response.data = dioResponse.data;
      return Result.ok(response);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<FetchResponse<T>>> download<T>(
    FetchRequest request,
    String filepath, {
    void Function(int count, int total)? progress,
  }) async {
    try {
      logger.debug("Downloading ${request.uri.toString()} to $filepath");
      final dioResponse = await _dio.downloadUri(
        request.uri,
        filepath,
        onReceiveProgress: progress,
      );
      final response = FetchResponse<T>(dioResponse.statusCode!);
      response.data = dioResponse.data as T;
      return Result.ok(response);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<FetchResponse<T>>> post<T>(FetchRequest request) {
    // TODO: implement post
    throw UnimplementedError();
  }
}
