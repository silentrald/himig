import "dart:io";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:himig/backend/database/main.dart";
import "package:himig/backend/repos/album/sqflite.dart";
import "package:himig/backend/repos/song/sqflite.dart";
import "package:himig/backend/repos/source/sqflite.dart";
import "package:himig/backend/repos/sqflite.dart";
import "package:himig/backend/services/fetch/dio.dart";
import "package:himig/backend/services/metadata/audio_metadata_reader.dart";
import "package:himig/backend/services/player/main.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/backend/services/source/folder.dart";
import "package:himig/backend/services/source/subsonic.dart";
import "package:himig/backend/services/source/v1.dart";
import "package:himig/backend/use_cases/album/types.dart";
import "package:himig/backend/use_cases/album/v1.dart";
import "package:himig/backend/use_cases/home/types.dart";
import "package:himig/backend/use_cases/home/v1.dart";
import "package:himig/backend/use_cases/settings/types.dart";
import "package:himig/backend/use_cases/settings/v1.dart";
import "package:himig/constant.dart" as constant;
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final getIt = GetIt.instance;

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(linux: true, windows: false);
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // === Repositories === //
  final sqfliteDatabase = await openDatabase(
    "himig.sql",
    version: constant.databaseVersion,
    onCreate: onCreateDatabase,
    onUpgrade: onUpgradeDatabase,
    onDowngrade: onDowngradeDatabase,
  );
  final database = SqfliteRepoDatabase(database: sqfliteDatabase);

  final albumRepo = SqfliteAlbumRepo();
  final songRepo = SqfliteSongRepo();
  final sourceRepo = SqfliteSourceRepo();

  //final fetchService = HttpFetchService();
  final fetchService = DioFetchService();
  final metadataService = AudioMetadataReaderMetadataService();

  final folderSourceImpl = FolderSourceImplementation(
    albumRepo: albumRepo,
    songRepo: songRepo,
    metadataService: metadataService,
  );
  final subsonicSourceImpl = SubsonicSourceImplementation(
    albumRepo: albumRepo,
    songRepo: songRepo,
    fetchService: fetchService,
  );

  final sourceService = MainSourceService(
    folderSourceImpl: folderSourceImpl,
    subsonicSourceImpl: subsonicSourceImpl,
  );

  //final storageService = SharedPreferenceStorageService();

  getIt.registerSingletonAsync<PlayerService>(() async {
    final player = MainPlayerService();
    await player.init("com.silentrald.himig.channel.audio", "Himig");
    return player;
  });

  // UseCases
  getIt.registerLazySingleton<HomeUseCase>(
    () => HomeUseCaseV1(database: database, albumRepo: albumRepo),
  );
  getIt.registerLazySingleton<AlbumUseCase>(
    () => AlbumUseCaseV1(
      database: database,
      songRepo: songRepo,
      fetchService: fetchService,
      sourceService: sourceService,
    ),
  );
  final settingsUseCase = SettingsUseCaseV1(
    database: database,
    sourceRepo: sourceRepo,
    albumRepo: albumRepo,
    songRepo: songRepo,
    sourceService: sourceService,
  );
  getIt.registerSingleton<SettingsUseCase>(settingsUseCase);

  await getIt.allReady();

  // Initialization
  await settingsUseCase.loadSources();
}

T getInject<T extends Object>() {
  return getIt<T>();
}
