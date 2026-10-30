import "package:flutter/material.dart";
import "package:himig/backend/dtos/album_songs.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/backend/use_cases/artist/types.dart";
import "package:himig/frontend/components/cards/album_card.dart";
import "package:himig/frontend/components/generic/uri_image.dart";
import "package:himig/frontend/components/song/song_item.dart";
import "package:himig/inject.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class ArtistPage extends StatefulWidget {
  final Artist artist;

  const ArtistPage({super.key, required this.artist});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final _playerService = getInject<PlayerService>();
  final _artistUseCase = getInject<ArtistUseCase>();

  final _artistImageSize = 48.0;
  final _trackImageSize = 64.0;
  final _paddingSize = 8.0;
  final _iconSize = 32.0;

  final List<AlbumSongsDto> _albumSongs = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _load();
    });
  }

  Future<void> _load() async {
    final result = await _artistUseCase.getAlbumSongsList(widget.artist.id);
    if (result is ResultError) {
      logger.error("Could not get album/songs list", error: result.error);
      return;
    }

    setState(() {
      _albumSongs.clear();
      _albumSongs.addAll(result.value);
    });
  }

  void _onAlbumPressed(Album album) {
    Navigator.pushNamed(context, "/album", arguments: {"album": album});
  }

  Future<void> _onSongItemPressed(Song selectedSong) async {
    final songs = _albumSongs
        .map((v) => v.songs)
        .fold<List<Song>>([], (previous, element) => previous..addAll(element));
    final index = songs.indexWhere((song) => song.id == selectedSong.id);
    if (index == -1) {
      logger.error("Could not find `${selectedSong.title}` song");
      return;
    }

    await _playerService.playSongList(songs, index: index);
  }

  Future<void> _cache() async {
    final result = await _artistUseCase.cacheArtist(widget.artist.id);
    if (result is ResultError) {
      logger.error("Could not cache artist's songs", error: result.error);
    }

    _load();
  }

  Future<void> _playArtistSongList({required bool shuffle}) async {
    final songs = _albumSongs
        .map((v) => v.songs)
        .fold<List<Song>>([], (previous, element) => previous..addAll(element));
    await _playerService.playSongList(songs, shuffle: shuffle);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: locale.translate(.generic, "tracks")),
              Tab(text: locale.translate(.generic, "albums")),
            ],
          ),
          title: Row(
            spacing: 8.0,
            children: [
              UriImage(
                widget.artist.imageUri,
                width: _artistImageSize,
                height: _artistImageSize,
              ),
              Text(widget.artist.name),
            ],
          ),
          toolbarHeight: _artistImageSize + 2 * _paddingSize,
        ),
        body: TabBarView(
          children: [_buildTrackList(locale), _buildAlbumList(locale, width)],
        ),
      ),
    );
  }

  Widget _buildTrackList(AppLocalizations locale) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildButtons(),
          ..._albumSongs.map((as) => _buildTrack(locale, as)),
        ],
      ),
    );
  }

  Widget _buildTrack(AppLocalizations locale, AlbumSongsDto albumSongs) {
    final album =
        albumSongs.album ??
        Album(name: locale.translate(.generic, "singles"), reference: "");
    final songs = albumSongs.songs;

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: .start,
        children: [
          GestureDetector(
            onTap: () => _onAlbumPressed(album),
            child: Row(
              children: [
                UriImage(
                  album.coverArtUri,
                  width: _trackImageSize,
                  height: _trackImageSize,
                ),

                Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(album.name),
                    Text(album.releaseYear?.toString() ?? ""),
                  ],
                ),
              ],
            ),
          ),

          ...songs.map(
            (song) => SongItem(
              song,
              width: constraints.maxWidth,
              onTap: () => _onSongItemPressed(song),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: .end,
      children: [
        // NOTE: check when should this be hidden for artists
        IconButton(
          onPressed: () => _cache(),
          icon: Icon(Icons.download, size: _iconSize),
        ),
        IconButton(
          onPressed: () => _playArtistSongList(shuffle: true),
          icon: Icon(Icons.shuffle, size: _iconSize),
        ),
        IconButton(
          onPressed: () => _playArtistSongList(shuffle: false),
          icon: Icon(Icons.play_arrow, size: _iconSize),
        ),
      ],
    );
  }

  Widget _buildAlbumList(AppLocalizations locale, double width) {
    final count = width > 1024 ? 3 : 2;
    final imageWidth = (width - (count + 1) * _paddingSize) / count;
    final albums = _albumSongs.map((as) {
      final album =
          as.album ??
          Album(name: locale.translate(.generic, "singles"), reference: "");
      return AlbumCard(
        album,
        imageSize: imageWidth,
        showArtistText: false,
        onTap: () => _onAlbumPressed(album),
      );
    }).toList();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(_paddingSize),
        child: Wrap(
          spacing: _paddingSize,
          runSpacing: _paddingSize,
          direction: .horizontal,
          children: albums,
        ),
      ),
    );
  }
}
