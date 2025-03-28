import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos in MP4 format (H.264 + AAC).
///
/// Uses `libx264` for video encoding with configurable CRF, preset, pixel
/// format, and audio codec. Designed for compatibility and efficient
/// compression.
class Mp4EncodingConfig extends VideoEncodingConfig {
  /// Creates an [Mp4EncodingConfig] with optional custom settings.
  const Mp4EncodingConfig({
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

  /// Pixel format for compatibility (e.g., `yuv420p` is widely supported).
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
