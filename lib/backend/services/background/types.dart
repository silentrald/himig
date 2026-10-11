abstract class BackgroundService {
  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  );
}

abstract class BackgroundServiceImpl {
  void Function() listen(
    String id,
    void Function(Map<String, dynamic>?) callback,
  );
  void invoke(String id, [Map<String, dynamic>? arguments]);

  void stop();
}
