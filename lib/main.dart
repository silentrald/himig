import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/services/background/main.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/frontend/components/now_playing_bar.dart";
import "package:himig/frontend/controllers/locale.dart";
import "package:himig/frontend/pages/album_page.dart";
import "package:himig/frontend/pages/artist_page.dart";
import "package:himig/frontend/pages/home_page.dart";
import "package:himig/frontend/pages/now_playing.dart";
import "package:himig/frontend/pages/settings_page.dart";
import "package:himig/inject.dart" as inject;
import "package:himig/locales/app_localizations.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await inject.setup();
  await initializeBackgroundService();

  final localeController = LocaleController();
  await localeController.initialize();

  runApp(HimigApp(localeController: localeController));

  await constant.setup();
}

class HimigApp extends StatefulWidget {
  final LocaleController localeController;

  const HimigApp({super.key, required this.localeController});

  @override
  State<StatefulWidget> createState() => _HimigAppState();
}

class _HimigAppState extends State<HimigApp> {
  final _playerService = inject.getInject<PlayerService>();
  final _barHeight = 50.0 + 16.0;

  bool _showNowPlayingPage = false;
  SimpleSong? _song;

  late void Function() _changeSongOnEnd;

  @override
  void initState() {
    super.initState();
    widget.localeController.addListener(_onLocaleChange);

    _changeSongOnEnd = _playerService.onSongChanged((song) {
      setState(() => _song = song);
    });
  }

  @override
  void dispose() {
    widget.localeController.removeListener(_onLocaleChange);
    _changeSongOnEnd();
    super.dispose();
  }

  void _onLocaleChange() {
    // Rebuild app when locale changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Himig",
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.red)),
      onGenerateRoute: (settings) =>
          _getRoute(settings, widget.localeController),
      initialRoute: "/home",
      builder: _getBuilder,

      locale: widget.localeController.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (widget.localeController.locale != null) {
          return widget.localeController.locale;
        }

        for (final locale in supportedLocales) {
          if (locale.languageCode == deviceLocale?.languageCode) {
            return locale;
          }
        }

        return Locale("en", "US");
      },
    );
  }

  Widget _getBuilder(BuildContext context, Widget? child) {
    // TODO: try to override the back button here
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: _showNowPlayingPage
            ? [NowPlayingPage(song: _song!)]
            : [
                Container(
                  margin: EdgeInsets.only(
                    bottom: _song == null ? 8.0 : _barHeight + 8.0,
                  ),
                  child: Align(alignment: Alignment.topCenter, child: child),
                ),

                ?((_song != null)
                    ? NowPlayingBar(
                        height: _barHeight,
                        song: _song!,
                        onSongInfoPressed: () {
                          setState(() => _showNowPlayingPage = true);
                        },
                      )
                    : null),
              ],
      ),
    );
  }

  Route<dynamic>? _getRoute(
    RouteSettings settings,
    LocaleController localeController,
  ) {
    final arguments = (settings.arguments ?? <String, dynamic>{}) as Map;

    switch (settings.name) {
      case "/home":
        return _buildRoute(
          settings,
          HomePage(localeController: localeController),
        );
      case "/album":
        return _buildRoute(settings, AlbumPage(album: arguments["album"]));
      case "/settings":
        return _buildRoute(
          settings,
          SettingsPage(localeController: localeController),
        );
      case "/artist":
        return _buildRoute(settings, ArtistPage(artist: arguments["artist"]));
      default:
        return null;
    }
  }

  MaterialPageRoute _buildRoute(RouteSettings settings, Widget builder) {
    return MaterialPageRoute(settings: settings, builder: (context) => builder);
  }
}
