import "dart:io";

import "package:himig/backend/dtos/audio_metadata.dart";
import "package:himig/utils/result.dart";

abstract class MetadataService {
  FutureResult<AudioMetadataDto> getAudioMetadata(File file);
}
