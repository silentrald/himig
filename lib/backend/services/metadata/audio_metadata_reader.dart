import "dart:io";

import "package:audio_metadata_reader/audio_metadata_reader.dart"
    as audio_metadata_reader;
import "package:himig/backend/entities/audio_metadata.dart";
import "package:himig/backend/services/metadata/types.dart";
import "package:himig/utils/result.dart";

class AudioMetadataReaderMetadataService extends MetadataService {
  @override
  Future<Result<AudioMetadata>> getAudioMetadata(File file) async {
    try {
      final metadata = audio_metadata_reader.readMetadata(file, getImage: true);
      return Result.ok(
        AudioMetadata(
          title: metadata.title,
          album: metadata.album,
          artist: metadata.artist,
          releaseYear: metadata.year?.year,
          duration: metadata.duration?.inSeconds,
          image: metadata.pictures.elementAtOrNull(0)?.bytes,
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
