import "package:himig/backend/errors/project_error.dart";

class MultiProjectError implements Exception {
  final List<ProjectError> errors;

  const MultiProjectError(this.errors);
}
