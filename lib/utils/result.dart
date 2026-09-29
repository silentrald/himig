// from https://docs.flutter.dev/app-architecture/design-patterns/result

/// Utility class that simplifies handling errors.
///
/// Return a [Result] from a function to indicate success or failure.
///
/// A [Result] is either an [Ok] with a value of type [T]
/// or an [Error] with an [Exception].
///
/// Use [Result.ok] to create a successful result with a value of type [T].
/// Use [Result.error] to create an error result with an [Exception].
sealed class Result<T> {
  T get value;
  Exception get error;

  const Result();

  /// Creates an instance of Result containing a value
  factory Result.ok(T value) => ResultOk(value);

  factory Result.error(Exception error) =>
      ResultError(error, StackTrace.current);

  /// Create an instance of Result containing an error
  factory Result.errorWithStackTrace(Exception error, StackTrace stackTrace) =>
      ResultError(error, stackTrace);

  // Explicit casting
  ResultError<To> toError<To>() {
    assert(this is ResultError);
    return ResultError(error, (this as ResultError).stackTrace);
  }
}

/// Subclass of Result for values
final class ResultOk<T> extends Result<T> {
  const ResultOk(this.value);

  @override
  final T value;

  @override
  Exception get error =>
      throw Exception("Dev Error: Result is ResultOk not ResultError");

  @override
  String toString() {
    return "Result value: $value";
  }
}

/// Subclass of Result for errors
final class ResultError<T> extends Result<T> {
  const ResultError(this.error, this.stackTrace);

  @override
  final Exception error;
  final StackTrace? stackTrace;

  @override
  T get value =>
      throw Exception("Dev Error: Result is ResultError not ResultOk");

  @override
  String toString() {
    return "$error\n$stackTrace";
  }
}

typedef FutureResult<T> = Future<Result<T>>;
