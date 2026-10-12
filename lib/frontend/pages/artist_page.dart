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

  final List<AlbumSongsDto> _albumSongs = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await _artistUseCase.getAlbumSongsList(widget.artist.id);
      if (result is ResultError) {
        logger.error("Could not get album/songs list", error: result.error);
        return;
      }

      setState(() => _albumSongs.addAll(result.value));
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

    await _playerService.clearQueue();
    await _playerService.addSongList(songs);
    await _playerService.skip(index);
    await _playerService.play();
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
              Tab(text: locale.app(.generic, "tracks")),
              Tab(text: locale.app(.generic, "albums")),
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
        body: TabBarView(children: [_buildTrackList(), _buildAlbumList(width)]),
      ),
    );
  }

  Widget _buildTrackList() {
    return SingleChildScrollView(
      child: Column(
        children: _albumSongs.map((as) => _buildTrack(as)).toList(),
      ),
    );
  }

  Widget _buildTrack(AlbumSongsDto albumSongs) {
    final album = albumSongs.album;
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

  Widget _buildAlbumList(double width) {
    final count = width > 1024 ? 3 : 2;
    final imageWidth = (width - (count + 1) * _paddingSize) / count;
    final albums = _albumSongs
        .map(
          (as) => AlbumCard(
            as.album,
            imageSize: imageWidth,
            showArtistText: false,
            onTap: () => _onAlbumPressed(as.album),
          ),
        )
        .toList();

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
