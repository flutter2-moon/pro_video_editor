import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos in MOV format (H.264 + AAC).
///
/// Uses `libx264` for video and `aac` for audio by default.
/// Similar to MP4, but packaged in a MOV container, typically used in Apple
/// ecosystems.
class MovEncodingConfig extends VideoEncodingConfig {
  /// Creates a [MovEncodingConfig] with optional custom settings.
  const MovEncodingConfig({
    this.crf = 23,
    this.preset = 'fast',
    this.pixelFormat = 'yuv420p',
    this.audioCodec = 'aac',
    super.customArgs,
  });

  /// Constant Rate Factor (CRF) for controlling video quality.
  ///
  /// Lower values result in higher quality (range: 0–51, default: 23).
  final int crf;

  /// Encoding speed preset (e.g., `ultrafast`, `fast`, `medium`, `slow`).
  ///
  /// Faster presets yield larger files; slower presets compress better.
  final String preset;

  /// Pixel format for compatibility (default: `yuv420p`).
  final String pixelFormat;

  /// Audio codec to use (default: `aac`).
  final String audioCodec;

  @override
  List<String> toFFmpegArgs() {
    return [
      /// Set video codec to H.264 (widely supported)
      '-c:v', 'libx264',

      /// Constant Rate Factor: quality (lower = better)
      '-crf', '$crf',

      /// Encoding speed vs. compression ratio
      '-preset', preset,

      /// Pixel format
      '-pix_fmt', pixelFormat,

      /// Audio encoding
      '-c:a', audioCodec,
      ...customArgs,
    ];
  }
}
