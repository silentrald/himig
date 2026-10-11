import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter_background_service/flutter_background_service.dart";
import "package:himig/backend/repos/album/sqflite.dart";
import "package:himig/backend/repos/artist/sqflite.dart";
import "package:himig/backend/repos/song/sqflite.dart";
import "package:himig/backend/repos/source/sqflite.dart";
import "package:himig/backend/repos/sqflite.dart";
import "package:himig/backend/services/background/desktop.dart";
import "package:himig/backend/services/background/mobile.dart";
import "package:himig/backend/services/background/types.dart";
import "package:himig/backend/services/fetch/dio.dart";
import "package:himig/backend/services/metadata/audio_metadata_reader.dart";
import "package:himig/backend/services/source/folder.dart";
import "package:himig/backend/services/source/subsonic.dart";
import "package:himig/backend/services/source/v1.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

Future<void> initializeBackgroundService() async {
  if (Platform.isIOS || Platform.isAndroid) {
    final service = FlutterBackgroundService();
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onMobileStart,
        onBackground: (_) => true,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: _onMobileStart,
        isForegroundMode: false,
        autoStartOnBoot: true,
        notificationChannelId: "com.silentrald.himig.channel.scanner",
        foregroundServiceNotificationId: 123456,
      ),
    );
    return;
  }

  await initializeDesktopBackgroundService();
  _onStart(DesktopBackgroundServiceImpl());
}

@pragma("vm:entry-point")
void _onMobileStart(ServiceInstance serviceInstance) =>
    _onStart(MobileBackgroundServiceImpl(serviceInstance));

void _onStart(BackgroundServiceImpl service) async {
  logger.info("Setting up scanning service");

  final sqfliteDatabase = await openDatabase(
    "himig.sql",
    version: constant.databaseVersion,
  );

  final database = SqfliteRepoDatabase(database: sqfliteDatabase);
  final albumRepo = SqfliteAlbumRepo();
  final artistRepo = SqfliteArtistRepo();
  final songRepo = SqfliteSongRepo();
  final sourceRepo = SqfliteSourceRepo();

  final fetchService = DioFetchService();
  final metadataService = AudioMetadataReaderMetadataService();

  final folderSourceImpl = FolderSourceImplementation(
    albumRepo: albumRepo,
    artistRepo: artistRepo,
    songRepo: songRepo,
    metadataService: metadataService,
  );
  final subsonicSourceImpl = SubsonicSourceImplementation(
    albumRepo: albumRepo,
    artistRepo: artistRepo,
    songRepo: songRepo,
    fetchService: fetchService,
  );

  final sourceService = MainSourceService(
    folderSourceImpl: folderSourceImpl,
    subsonicSourceImpl: subsonicSourceImpl,
  );

  final List<Timer> timers = [];
  service.listen("stop", (_) {
    logger.info("Stopping scanning service");
    for (final t in timers) {
      t.cancel();
    }
    service.stop();
  });

  // === Start Scanning Service === //

  void scanSources() async {
    logger.info("Start scanning sources");

    final sources = await sourceRepo.getAllSources(database.client);
    if (sources is ResultError) {
      logger.error("Could not get sources", error: sources.error);
      return;
    }

    final Map<String, bool> map = {};
    for (final source in sources.value) {
      final result = await sourceService.isConnected(source);
      if (result is ResultError) {
        logger.error("Error in scanning ${source.name}", error: result.error);
        continue;
      }

      map[source.id.toString()] = result.value;
      if (result.value) {
        logger.debug("Source `${source.name}` connected");
      } else {
        logger.debug("Source `${source.name}` not connected");
      }
    }

    // Can only support passing string data to invoke
    service.invoke("sources", {"data": jsonEncode(map)});
    logger.info("End scanning sources");
  }

  logger.info("Scanning service setup complete");
  scanSources();
  timers.add(
    Timer.periodic(
      const Duration(minutes: constant.scanningInterval),
      (_) => scanSources(),
    ),
  );
  // For Debugging
  // timers.add(Timer.periodic(const Duration(seconds: 15), (_) => scanSources()));

  // === End Scanning Service === //
}
