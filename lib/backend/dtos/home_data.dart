import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";

class HomeData {
  List<Artist> artists;
  List<Album> albums;
  Map<int, bool> connectedSources;

  HomeData({
    required this.artists,
    required this.albums,
    required this.connectedSources,
  });
}
