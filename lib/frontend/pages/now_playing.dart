import "package:flutter/material.dart";
import "package:himig/backend/entities/song.dart";

class NowPlayingPage extends StatefulWidget {
  final SimpleSong song;

  const NowPlayingPage({super.key, required this.song});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: .spaceBetween,
        children: [Text("Image"), Text("Slider"), Text("Media Buttons")],
      ),
    );
  }
}
