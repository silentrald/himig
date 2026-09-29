import "dart:convert";

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
    int id = 0,
    required String name,
    required String path,
    required bool writeable,
  }) : _id = id,
       _name = name,
       _path = path,
       _writeable = writeable;

  factory FolderSource.fromRepo(
    int id,
    String name,
    Map<String, dynamic> json,
  ) {
    return FolderSource(
      id: id,
      name: name,
      path: json["path"],
      writeable: json["writeable"],
    );
  }

  static String? validateName(String name) {
    if (name.isEmpty) return "name is empty";
    return null;
  }

  static String? validatePath(String path) {
    if (path.isEmpty) return "path is empty";
    return null;
  }

  static Result<FolderSource> create({
    required int id,
    required String name,
    required String path,
    required bool writeable,
  }) {
    final List<String> errors = [?validateName(name), ?validatePath(path)];
    if (errors.isNotEmpty) {
      return Result.error(Exception(errors.join(",")));
    }

    return Result.ok(
      FolderSource(id: id, name: name, path: path, writeable: writeable),
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

  SubsonicSource._(
    this._id,
    this._name,
    this._https,
    this._host,
    this._username,
    this._hashedPassword,
    this._salt,
    this._localSourceId,
  );

  factory SubsonicSource.createUnsafe({
    int id = 0,
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
      id,
      name,
      address.startsWith("https://"),
      address.substring(https ? 8 : 7),
      username,
      hashMd5("$password$salt"),
      salt,
      localSourceId,
    );
  }

  factory SubsonicSource.fromRepo(
    int id,
    String name,
    Map<String, dynamic> json,
  ) {
    return SubsonicSource._(
      id,
      name,
      json["https"],
      json["host"],
      json["username"],
      json["password"],
      json["salt"],
      json["localSourceId"],
    );
  }

  // === Validation Checks === //

  static String? validateName(String name) {
    if (name.isEmpty) return "name is empty";
    return null;
  }

  static String? validateUsername(String username) {
    if (username.isEmpty) return "username is empty";
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return "password is empty";
    return null;
  }

  static String? validateAddress(String address) {
    if (address.isEmpty) return "address is empty";
    if (!address.startsWith("https://") && !address.startsWith("http://")) {
      return "address should start with 'http' or 'https'";
    }
    return null;
  }

  static Result<SubsonicSource> create({
    int id = 0,
    required String name,
    required String address,
    required String username,
    required String password,
    int? localSourceId,
    int saltLength = 6,
  }) {
    final List<String> errors = [
      ?validateName(name),
      ?validateUsername(username),
      ?validatePassword(password),
      ?validateAddress(address),
    ];
    if (errors.isNotEmpty) {
      return Result.error(Exception(errors.join(",")));
    }

    return Result.ok(
      SubsonicSource.createUnsafe(
        id: id,
        name: name,
        address: address,
        username: username,
        password: password,
        localSourceId: localSourceId,
        saltLength: saltLength,
      ),
    );
  }

  SubsonicSource copy() {
    return SubsonicSource._(
      _id,
      _name,
      _https,
      _host,
      _username,
      _hashedPassword,
      _salt,
      _localSourceId,
    );
  }

  Uri getUri(String path, Map<String, String> parameters) =>
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
  String? setName(String name) {
    final error = validateName(name);
    if (error == null) _name = name;
    return error;
  }

  /// Returns the string error code
  String? setAddress(String address) {
    final error = validateAddress(address);
    if (error == null) {
      _https = address.startsWith("https://");
      _host = address.substring(_https ? 8 : 7);
    }
    return error;
  }

  /// Returns the string error code
  String? setUsername(String username) {
    final error = validateUsername(username);
    if (error == null) _username = username;
    return error;
  }

  /// Returns the string error code
  String? setPassword(String password, {int saltLength = 6}) {
    final error = validatePassword(password);
    if (error == null) {
      _salt = getRandomString(saltLength);
      _hashedPassword = hashMd5("$password$_salt");
    }
    return error;
  }

  String? setLocalSourceId(int? localSourceId) {
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
