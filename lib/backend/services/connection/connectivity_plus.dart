import "package:connectivity_plus/connectivity_plus.dart";
import "package:himig/backend/services/connection/types.dart";

class ConnectivityPlusConnectionService extends ConnectionService {
  @override
  void Function() onConnectionChange(void Function(bool) callback) {
    final subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      callback(result.hasConnectivity);
    });
    return () => subscription.cancel();
  }
}
