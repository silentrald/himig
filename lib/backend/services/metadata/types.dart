import "dart:io";

import "package:himig/backend/entities/audio_metadata.dart";
import "package:himig/utils/result.dart";

abstract class MetadataService {
  Future<Result<AudioMetadata>> getAudioMetadata(File file);
}
