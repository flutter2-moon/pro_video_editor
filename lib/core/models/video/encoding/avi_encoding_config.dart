import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos in AVI format.
///
/// Uses `mpeg4` for video and `mp3` for audio by default.
/// Quality is controlled via a quantizer scale (qscale), where lower = better.
class AviEncodingConfig extends VideoEncodingConfig {
  /// Creates an [AviEncodingConfig] with optional custom settings.
  const AviEncodingConfig({
    this.videoCodec = 'mpeg4',
    this.qualityScale = 5,
    this.audioCodec = 'mp3',
    super.customArgs,
  });

  /// The video codec to use (default: `mpeg4`).
  final String videoCodec;

  /// Visual quality scale (1–31). Lower values result in better quality
  /// (default: 5).
  final int qualityScale;

  /// The audio codec to use (default: `mp3`).
  final String audioCodec;

  @override
  List<String> toFFmpegArgs() {
    return [
      ///
      '-c:v', videoCodec,

      ///
      '-qscale:v', '$qualityScale',

      ///
      '-c:a', audioCodec,
      ...customArgs,
    ];
  }
}
