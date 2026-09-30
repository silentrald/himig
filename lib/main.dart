import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/frontend/components/now_playing_bar.dart";
import "package:himig/frontend/pages/album_page.dart";
import "package:himig/frontend/pages/home_page.dart";
import "package:himig/frontend/pages/settings_page.dart";
import "package:himig/inject.dart" as inject;
import "package:himig/locale.dart";
import "package:himig/locales/app_localizations.dart";

Future<void> main() async {
  await inject.setup();

  final localeController = LocaleController();
  await localeController.initialize();

  runApp(HimigApp(localeController: localeController));

  await constant.setup();
}

class HimigApp extends StatefulWidget {
  final LocaleController localeController;
  final double _barHeight = 50.0;

  const HimigApp({super.key, required this.localeController});

  @override
  State<StatefulWidget> createState() => _HimigAppState();
}

class _HimigAppState extends State<HimigApp> {
  @override
  void initState() {
    super.initState();
    widget.localeController.addListener(_onLocaleChange);
  }

  @override
  void dispose() {
    widget.localeController.removeListener(_onLocaleChange);
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
      home: HomePage(localeController: widget.localeController),
      builder: _getBuilder,

      locale: widget.localeController.locale,
      supportedLocales: constant.supportedLocales,
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

        return Locale("en");
      },
    );
  }

  Widget _getBuilder(BuildContext context, Widget? child) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: widget._barHeight + 8.0),
            child: Align(alignment: Alignment.topCenter, child: child),
          ),
          SizedBox(
            height: widget._barHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: NowPlayingBar(),
            ),
          ),
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
      default:
        return null;
    }
  }

  MaterialPageRoute _buildRoute(RouteSettings settings, Widget builder) {
    return MaterialPageRoute(settings: settings, builder: (context) => builder);
  }
}
