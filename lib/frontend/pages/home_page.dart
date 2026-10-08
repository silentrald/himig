import "package:flutter/material.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/use_cases/home/types.dart";
import "package:himig/frontend/components/cards/album_card.dart";
import "package:himig/frontend/components/cards/artist_card.dart";
import "package:himig/frontend/controllers/locale.dart";
import "package:himig/inject.dart";
import "package:himig/locales/app_localizations.dart";
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

  final _artistController = ScrollController();
  int _artistPage = 1;
  final List<Artist> _artists = [];

  final _sectionHeight = 300.0;

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _albumPage = 1;
        _albums.clear();

        _artistPage = 1;
        _artists.clear();
      });

      final albumResult = await _homeUseCase.getAlbumList(page: _albumPage);
      if (albumResult is ResultError) {
        logger.error("Could not get album list", error: albumResult.error);
        return;
      }

      final artistResult = await _homeUseCase.getArtistList(page: _artistPage);
      if (artistResult is ResultError) {
        logger.error("Could not get artist list", error: artistResult.error);
        return;
      }

      setState(() {
        _albums.addAll(albumResult.value);
        _artists.addAll(artistResult.value);
      });
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

    _artistController.addListener(() async {
      if (_artistPage == -1) {
        return;
      }

      if (_artistController.offset >=
              _artistController.position.maxScrollExtent &&
          !_artistController.position.outOfRange) {
        ++_artistPage;
        logger.info("Artists loading page $_artistPage");

        final result = await _homeUseCase.getArtistList(page: _artistPage);
        if (result is ResultError) {
          logger.error("Could not get artist list", error: result.error);
          return;
        }

        final List<Artist> newArtists = result.value;
        if (newArtists.isEmpty) {
          _artistPage = -1;
          return;
        }

        setState(() => _artists.addAll(newArtists));
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

  void _onAlbumCardPressed(Album album) {
    Navigator.pushNamed(context, "/album", arguments: {"album": album});
  }

  void _onArtistCardPressed(Artist artist) {
    Navigator.pushNamed(context, "/artist", arguments: {"artist": artist});
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.instance;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(locale.app(.generic, "albums")),

            _buildAlbums(locale),

            Text(locale.app(.generic, "artists")),

            _buildArtists(locale),

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
      ),
    );
  }

  Widget _buildAlbums(AppLocalizations locale) {
    return SizedBox(
      height: _sectionHeight,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        itemCount: _albums.length,
        separatorBuilder: (_, _) => SizedBox(width: 16),
        itemBuilder: (context, index) => AlbumCard(
          _albums[index],
          onTap: () => _onAlbumCardPressed(_albums[index]),
        ),
        controller: _albumController,
      ),
    );
  }

  Widget _buildArtists(AppLocalizations locale) {
    return SizedBox(
      height: _sectionHeight,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        itemCount: _artists.length,
        separatorBuilder: (_, _) => SizedBox(width: 16),
        itemBuilder: (context, index) => ArtistCard(
          artist: _artists[index],
          onTap: () => _onArtistCardPressed(_artists[index]),
        ),
        controller: _artistController,
      ),
    );
  }
}
