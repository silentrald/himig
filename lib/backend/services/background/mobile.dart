import "package:flutter_background_service/flutter_background_service.dart";
import "package:himig/backend/services/background/types.dart";

class MobileBackgroundService extends BackgroundService {
  @override
  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  ) {
    final subscription = FlutterBackgroundService().on(id).listen(callback);
    return () => subscription.cancel();
  }
}

class MobileBackgroundServiceImpl extends BackgroundServiceImpl {
  final ServiceInstance _service;

  MobileBackgroundServiceImpl(this._service);

  @override
  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  ) {
    final subscription = _service.on(id).listen(callback);
    return () => subscription.cancel();
  }

  @override
  void invoke(String id, [Map<String, dynamic>? arguments]) {
    _service.invoke(id, arguments);
  }

  @override
  void stop() {
    _service.stopSelf();
  }
}
