import "dart:io";

import "package:flutter/material.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/backend/use_cases/album/types.dart";
import "package:himig/frontend/components/song/song_item.dart";
import "package:himig/inject.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final _albumUseCase = getInject<AlbumUseCase>();
  final _playerService = getInject<PlayerService>();

  List<Song> _songs = [];

  Future<void> _load() async {
    final result = await _albumUseCase.getSongsByAlbum(widget.album.id);
    if (result is ResultError) {
      logger.error("Could not load songs ${result.error}");
      return;
    }

    setState(() => _songs = result.value);
  }

  Future<void> _cache() async {
    final result = await _albumUseCase.cacheAlbumSongs(widget.album);
    switch (result) {
      case ResultOk():
        logger.info("Cached album");
      case ResultError(:var error):
        logger.error("Error in caching ${error.toString()}.");
    }
  }

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _onSongItemPressed(int index) async {
    await _playerService.clearQueue();
    await _playerService.addSongList(_songs);
    await _playerService.skip(index);
    await _playerService.play();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: width, // So it would show as a square
          flexibleSpace: FlexibleSpaceBar(
            title: Text(widget.album.name),
            background: _buildImage(widget.album.coverArtUri),
          ),
          backgroundColor: Colors.transparent,
        ),

        ?_buildCacheButton(locale),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSongItem(index, width),
            childCount: _songs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(Uri? coverArtUri) {
    final theme = Theme.of(context);
    if (coverArtUri == null) {
      return Container(color: theme.colorScheme.primary);
    }

    if (coverArtUri.isScheme("file")) {
      return Image.file(File.fromUri(coverArtUri), fit: BoxFit.cover);
    }

    return Image.network(coverArtUri.toString(), fit: BoxFit.cover);
  }

  Widget? _buildCacheButton(AppLocalizations locale) {
    final source = AppState().getSource(widget.album.sourceId);

    if (!source.remote) return null;
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => _cache(),
        child: Text(locale.app(.generic, "cache")),
      ),
    );
  }

  SongItem _buildSongItem(int index, double width) {
    final Song song = _songs[index];
    return SongItem(song, width: width, onTap: () => _onSongItemPressed(index));
  }
}
