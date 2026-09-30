import "dart:async";

import "package:flutter/material.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/use_cases/home/types.dart";
import "package:himig/frontend/components/album/album_card.dart";
import "package:himig/inject.dart";
import "package:himig/locale.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class HomePage extends StatefulWidget {
  final LocaleController _localeController;
  const HomePage({super.key, required this._localeController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _homeUseCase = getInject<HomeUseCase>();

  final _albumController = ScrollController();
  int _albumPage = 1;
  final List<Album> _albums = [];

  Future<void> _load() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _albumPage = 1;
        _albums.clear();
      });

      final result = await _homeUseCase.getAlbumList(page: _albumPage);
      switch (result) {
        case ResultOk(:var value):
          setState(() => _albums.addAll(value));
        case ResultError(:var error):
          logger.error("Could not get album list", error: error);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    widget._localeController.addListener(_onLocaleChange);

    _albumController.addListener(() async {
      if (_albumPage == -1) {
        return;
      }

      if (_albumController.offset >=
              _albumController.position.maxScrollExtent &&
          !_albumController.position.outOfRange) {
        ++_albumPage;
        logger.info("Album loading page $_albumPage");

        final result = await _homeUseCase.getAlbumList(page: _albumPage);
        if (result is ResultError) {
          logger.error("Could not get album list", error: result.error);
          return;
        }

        final List<Album> newAlbums = result.value;
        if (newAlbums.isEmpty) {
          _albumPage = -1;
          return;
        }

        setState(() => _albums.addAll(newAlbums));
      }
    });
    _load();
  }

  @override
  void dispose() {
    widget._localeController.addListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() {
    // Base page of the application, needs to be re-rendered to apply the locale change
    // Delay the setState on the end the event loop, so the changes will be applied properly
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  void _onAlbumCardPressed(int index) {
    Navigator.pushNamed(
      context,
      "/album",
      arguments: {"album": _albums[index]},
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.instance;

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildAlbums(),

          TextButton(
            onPressed: () => Navigator.pushNamed(context, "/settings"),
            child: Text(locale.app(.generic, "settings")),
          ),

          TextButton(
            onPressed: () => _load(),
            child: Text(locale.app(.generic, "refresh")),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbums() {
    return SizedBox(
      height: 350,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        itemCount: _albums.length,
        separatorBuilder: (_, _) => SizedBox(width: 16),
        itemBuilder: (context, index) => AlbumCard(
          album: _albums[index].name,
          artist: _albums[index].artist,
          sourceType: AppState().getSource(_albums[index].sourceId).type,
          coverArtUri: _albums[index].coverArtUri,
          onTap: () => _onAlbumCardPressed(index),
        ),
        controller: _albumController,
      ),
    );
  }
}
