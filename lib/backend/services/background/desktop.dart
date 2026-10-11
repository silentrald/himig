import "dart:async";
import "dart:isolate";

import "package:himig/backend/services/background/types.dart";
import "package:rxdart/rxdart.dart";

Future<void> initializeDesktopBackgroundService() => _Worker.initialize();

class _Worker {
  static _Worker? _instance;
  static _Worker get instance => _instance!;

  final SendPort _commands;
  final ReceivePort _responses;
  final Map<String, Completer<Object?>> _activeRequests = {};

  BehaviorSubject<(String, Map<String, dynamic>?)>? _subject;
  bool get _open => _subject != null;

  static Future<void> initialize() async => _instance ??= await _spawn();

  _Worker._internal(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
    _subject = BehaviorSubject();
  }

  void invoke(String id, [Map<String, dynamic>? arguments]) {
    if (!_open) throw StateError("Closed");
    final completer = Completer<Object?>.sync();
    _activeRequests[id] = completer;
    _commands.send((id, arguments));
  }

  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  ) {
    if (!_open) throw StateError("Closed");
    final subscription = _subject!.listen((message) {
      if (message.$1 == id) {
        callback(message.$2);
      }
    });
    return () => subscription.cancel();
  }

  void close() {
    if (!_open) {
      return;
    }

    _subject?.close();
    _commands.send("shutdown");
    if (_activeRequests.isEmpty) _responses.close();
  }

  static Future<_Worker> _spawn() async {
    // Create a receive port and add its initial message handler.
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return _Worker._internal(receivePort, sendPort);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (id, response) = message as (String, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (!_open && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    receivePort.listen((message) {
      if (message == "shutdown") {
        receivePort.close();
        return;
      }

      final (id, arguments) = message as (String, Map<String, dynamic>?);
      try {
        sendPort.send((id, arguments));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), "")));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }
}

class DesktopBackgroundService extends BackgroundService {
  @override
  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  ) => _Worker.instance.listen(id, callback);
}

class DesktopBackgroundServiceImpl extends BackgroundServiceImpl {
  @override
  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  ) => _Worker.instance.listen(id, callback);

  @override
  void invoke(String id, [Map<String, dynamic>? arguments]) =>
      _Worker.instance.invoke(id, arguments);

  @override
  void stop() => _Worker.instance.close();
}
