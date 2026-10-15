import "dart:convert";

import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/utils/result.dart";
import "package:himig/utils/string.dart";

enum SourceType { folder, subsonic }

sealed class Source {
  int get id;
  String get name;
  bool get writeable;
  SourceType get type;

  bool get remote;
  int? get localSourceId;

  /// Serializes the object to be saved in a persistent storage
  String serialize();

  void setId(int id);
}

/// Folder Implementations

/// Songs are found in the external storage of the phone.
class FolderSource extends Source {
  int _id;
  String _name;
  String _path;
  // Check if the soruce will be writeable for music/songs
  bool _writeable;

  FolderSource({
    this._id = 0,
    required this._name,
    required this._path,
    required this._writeable,
  });

  factory FolderSource.fromRepo({
    required int id,
    required String name,
    required Map<String, dynamic> data,
  }) {
    return FolderSource(
      id: id,
      name: name,
      path: data["path"],
      writeable: data["writeable"],
    );
  }

  static ProjectError? validateName(String name) {
    if (name.isEmpty) return ProjectError(.entitySource, "folderNameRequired");
    return null;
  }

  static ProjectError? validatePath(String path) {
    if (path.isEmpty) return ProjectError(.entitySource, "folderPathRequired");
    return null;
  }

  static Result<FolderSource> create({
    required String name,
    required String path,
    required bool writeable,
  }) {
    final List<ProjectError> errors = [
      ?validateName(name),
      ?validatePath(path),
    ];
    if (errors.isNotEmpty) {
      return Result.error(MultiProjectError(errors));
    }

    return Result.ok(
      FolderSource(name: name, path: path, writeable: writeable),
    );
  }

  // === Getters / Setters === //

  @override
  int get id => _id;
  set id(int value) => _id = value;

  @override
  String get name => _name;

  @override
  bool get writeable => _writeable;

  @override
  SourceType get type => SourceType.folder;

  @override
  bool get remote => false;

  @override
  int? get localSourceId => null;

  @override
  void setId(int id) => _id = id;

  String get path => _path;

  @override
  String serialize() {
    return jsonEncode({"path": _path, "writeable": _writeable});
  }
}

/// API Implementations

/// Songs can be queried from any subsonic api server.
class SubsonicSource extends Source {
  int _id;
  String _name;
  bool _https;
  String _host;
  String _username;
  String _hashedPassword;
  String _salt;

  int? _localSourceId;

  SubsonicSource._({
    this._id = 0,
    required this._name,
    required this._https,
    required this._host,
    required this._username,
    required this._hashedPassword,
    required this._salt,
    required this._localSourceId,
  });

  factory SubsonicSource.createUnsafe({
    required String name,
    required String address,
    required String username,
    required String password,
    int? localSourceId,
    int saltLength = 6,
  }) {
    final https = address.startsWith("https://");
    final salt = getRandomString(saltLength);
    return SubsonicSource._(
      name: name,
      https: address.startsWith("https://"),
      host: address.substring(https ? 8 : 7),
      username: username,
      hashedPassword: hashMd5("$password$salt"),
      salt: salt,
      localSourceId: localSourceId,
    );
  }

  factory SubsonicSource.fromRepo({
    required int id,
    required String name,
    required Map<String, dynamic> json,
  }) => SubsonicSource._(
    id: id,
    name: name,
    https: json["https"],
    host: json["host"],
    username: json["username"],
    hashedPassword: json["password"],
    salt: json["salt"],
    localSourceId: json["localSourceId"],
  );

  // === Validation Checks === //

  static ProjectError? validateName(String name) {
    if (name.isEmpty)
      return ProjectError(.entitySource, "subsonicNameRequired");
    return null;
  }

  static ProjectError? validateUsername(String username) {
    if (username.isEmpty) {
      return ProjectError(.entitySource, "subsonicUsernameRequired");
    }
    return null;
  }

  static ProjectError? validatePassword(String password) {
    if (password.isEmpty) {
      return ProjectError(.entitySource, "subsonicPasswordRequired");
    }
    return null;
  }

  static ProjectError? validateAddress(String address) {
    if (address.isEmpty) {
      return ProjectError(.entitySource, "subsonicAddressRequired");
    }

    if (!address.startsWith("https://") && !address.startsWith("http://")) {
      return ProjectError(.entitySource, "addressProtocol");
    }

    return null;
  }

  static Result<SubsonicSource> create({
    required String name,
    required String address,
    required String username,
    required String password,
    int? localSourceId,
    int saltLength = 6,
  }) {
    final List<ProjectError> errors = [
      ?validateName(name),
      ?validateUsername(username),
      ?validatePassword(password),
      ?validateAddress(address),
    ];
    if (errors.isNotEmpty) {
      return Result.error(MultiProjectError(errors));
    }

    return Result.ok(
      SubsonicSource.createUnsafe(
        name: name,
        address: address,
        username: username,
        password: password,
        localSourceId: localSourceId,
        saltLength: saltLength,
      ),
    );
  }

  Result<SubsonicSource> copyWith({
    int? id,
    String? name,
    String? address,
    String? username,
    String? password,
    int? localSourceId,
    int saltLength = 6,
  }) {
    final List<ProjectError> errors = [];
    ProjectError? error;

    name ??= _name;
    username ??= _username;
    localSourceId ??= _localSourceId;

    bool isHttps = _https;
    String host = _host;
    if (address != null) {
      error = validateAddress(address);
      if (error == null) {
        isHttps = address.startsWith("https://");
        host = address.substring(https ? 8 : 7);
      } else {
        errors.add(error);
      }
    }

    var hashedPassword = _hashedPassword;
    var salt = _salt;
    if (password != null) {
      error = validatePassword(password);
      if (error == null) {
        salt = getRandomString(saltLength);
        hashedPassword = hashMd5("$password$salt");
      } else {
        errors.add(error);
      }
    }

    if (errors.isNotEmpty) {
      return Result.error(MultiProjectError(errors));
    }

    return Result.ok(
      SubsonicSource._(
        id: id ?? _id,
        name: name,
        https: isHttps,
        host: host,
        username: username,
        hashedPassword: hashedPassword,
        salt: salt,
        localSourceId: localSourceId,
      ),
    );
  }

  Uri getUri(String path, [Map<String, String> parameters = const {}]) =>
      (_https ? Uri.https : Uri.http)(_host, path, {
        ...parameters,
        "u": _username,
        "t": _hashedPassword,
        "s": _salt,
        "v": constant.version,
        "c": constant.appName,
      });

  // Getters / Setters
  @override
  int get id => _id;

  @override
  String get name => _name;

  @override
  bool get writeable => false; // Subsonic does not support uploading of files

  @override
  SourceType get type => SourceType.subsonic;

  @override
  bool get remote => true;

  @override
  int? get localSourceId => _localSourceId;

  @override
  void setId(int id) => _id = id;

  bool get https => _https;
  String get host => _host;
  String get username => _username;

  /// Returns the string error code
  ProjectError? setName(String name) {
    final error = validateName(name);
    if (error == null) _name = name;
    return error;
  }

  /// Returns the string error code
  ProjectError? setAddress(String address) {
    final error = validateAddress(address);
    if (error == null) {
      _https = address.startsWith("https://");
      _host = address.substring(_https ? 8 : 7);
    }
    return error;
  }

  /// Returns the string error code
  ProjectError? setUsername(String username) {
    final error = validateUsername(username);
    if (error == null) _username = username;
    return error;
  }

  /// Returns the string error code
  ProjectError? setPassword(String password, {int saltLength = 6}) {
    final error = validatePassword(password);
    if (error == null) {
      _salt = getRandomString(saltLength);
      _hashedPassword = hashMd5("$password$_salt");
    }
    return error;
  }

  ProjectError? setLocalSourceId(int? localSourceId) {
    _localSourceId = localSourceId;
    return null;
  }

  @override
  String serialize() {
    return jsonEncode({
      "https": _https,
      "host": _host,
      "username": _username,
      "password": _hashedPassword,
      "salt": _salt,
      "localSourceId": _localSourceId,
    });
  }
}
