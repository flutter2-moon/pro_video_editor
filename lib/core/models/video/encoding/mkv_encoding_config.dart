import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos in MKV format (H.264 + AAC).
///
/// Uses `libx264` for video and `aac` for audio by default.
/// The MKV container supports a wide range of codecs and advanced features.
class MkvEncodingConfig extends VideoEncodingConfig {
  /// Creates an [MkvEncodingConfig] with optional custom settings.
  const MkvEncodingConfig({
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

  /// Pixel format for compatibility (default: `yuv420p`).
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
  MkvEncodingConfig copyWith({
    int? crf,
    String? preset,
    String? pixelFormat,
    String? audioCodec,
  }) {
    return MkvEncodingConfig(
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      pixelFormat: pixelFormat ?? this.pixelFormat,
      audioCodec: audioCodec ?? this.audioCodec,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MkvEncodingConfig &&
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
