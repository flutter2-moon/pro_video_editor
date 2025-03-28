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
  List<String> toFFmpegArgs(bool enableAudio) {
    return [
      /// Set video codec to H.264 (widely supported)
      '-c:v', 'libx264',

      /// Constant Rate Factor: quality (lower = better)
      '-crf', '$crf',

      /// Encoding speed vs. compression ratio
      '-preset', preset,

      /// Pixel format
      '-pix_fmt', pixelFormat,

      /// Audio handling
      if (enableAudio) ...[
        '-c:a', audioCodec, // e.g., 'aac'
      ] else ...[
        '-an', // disable audio
      ],
      ...customArgs,
    ];
  }

  /// Returns a copy of this config with the given fields replaced.
  Mp4EncodingConfig copyWith({
    int? crf,
    String? preset,
    String? pixelFormat,
    String? audioCodec,
  }) {
    return Mp4EncodingConfig(
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      pixelFormat: pixelFormat ?? this.pixelFormat,
      audioCodec: audioCodec ?? this.audioCodec,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Mp4EncodingConfig &&
        other.crf == crf &&
        other.preset == preset &&
        other.pixelFormat == pixelFormat &&
        other.audioCodec == audioCodec;
  }

  @override
  int get hashCode {
    return crf.hashCode ^
        preset.hashCode ^
        pixelFormat.hashCode ^
        audioCodec.hashCode;
  }
}
