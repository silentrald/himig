import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/frontend/components/now_playing_bar.dart";
import "package:himig/frontend/pages/album_page.dart";
import "package:himig/frontend/pages/home_page.dart";
import "package:himig/frontend/pages/settings_page.dart";
import "package:himig/inject.dart" as inject;
import "package:himig/locales/app_localizations.dart";

Future<void> main() async {
  await inject.setup();

  runApp(const MyApp());

  await constant.setup();
}

class MyApp extends StatelessWidget {
  final double _barHeight = 50.0;

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Himig",
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.red)),
      onGenerateRoute: _getRoute,
      home: const HomePage(),
      builder: _getBuilder,

      // TODO: check https://flutterlocalisation.com/blog/flutter-change-language-runtime
      locale: const Locale("en"),
      supportedLocales: constant.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  Widget _getBuilder(BuildContext context, Widget? child) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: _barHeight + 8.0),
            child: Align(alignment: Alignment.topCenter, child: child),
          ),
          SizedBox(
            height: _barHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: NowPlayingBar(),
            ),
          ),
        ],
      ),
    );
  }

  Route<dynamic>? _getRoute(RouteSettings settings) {
    final arguments = (settings.arguments ?? <String, dynamic>{}) as Map;

    switch (settings.name) {
      case "/home":
        return _buildRoute(settings, const HomePage());
      case "/album":
        return _buildRoute(settings, AlbumPage(album: arguments["album"]));
      case "/settings":
        return _buildRoute(settings, const SettingsPage());
      default:
        return null;
    }
  }

  MaterialPageRoute _buildRoute(RouteSettings settings, Widget builder) {
    return MaterialPageRoute(settings: settings, builder: (context) => builder);
  }
}
