import "package:flutter/material.dart";
import "package:himig/backend/dtos/album_songs.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/backend/use_cases/artist/types.dart";
import "package:himig/frontend/components/generic/uri_image.dart";
import "package:himig/frontend/components/song/song_item.dart";
import "package:himig/inject.dart";
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

  final _trackImageSize = 64.0;

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
    await _playerService.clearQueue();

    int songIndex = -1;
    int index = 0;
    for (final albumSong in _albumSongs) {
      for (final song in albumSong.songs) {
        if (selectedSong.id == song.id && songIndex == -1) {
          songIndex = index;
        }

        await _playerService.addSong(song);
        ++index;
      }
    }

    await _playerService.skip(songIndex);
    await _playerService.play();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Back"),
          ),

          SizedBox(height: 8.0),

          UriImage(widget.artist.imageUri),

          SizedBox(height: 8.0),

          Text(widget.artist.name),

          SizedBox(height: 8.0),

          ..._albumSongs.map((as) => _buildTrack(as)),
        ],
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
}
