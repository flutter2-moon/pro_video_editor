import 'package:flutter/services.dart';

/// A model that holds all required data for exporting a video.
///
/// This includes the original video and image bytes, the desired output
/// format, quality settings, and duration.
class ExportVideoModel {
  /// Creates an [ExportVideoModel] instance.
  ///
  /// [outputFormat], [videoBytes], [imageBytes], and [videoDuration] are
  /// required. [outputQuality] and [encodingPreset] default to reasonable
  /// values.
  ExportVideoModel({
    required this.outputFormat,
    required this.videoBytes,
    required this.imageBytes,
    required this.videoDuration,
    this.outputQuality = OutputQuality.medium,
    this.encodingPreset = EncodingPreset.fast,
  });

  /// The target format for the exported video.
  final VideoOutputFormat outputFormat;

  /// The original video data in bytes.
  final Uint8List videoBytes;

  /// A reference image (e.g., thumbnail or overlay) in bytes.
  final Uint8List imageBytes;

  /// The duration of the output video.
  final Duration videoDuration;

  /// Desired visual quality for the output video.
  final OutputQuality outputQuality;

  /// FFmpeg encoding preset balancing speed and compression.
  final EncodingPreset encodingPreset;

  /// The FFmpeg constant rate factor (CRF) for the selected [outputQuality].
  ///
  /// Lower CRF means better quality and larger file size.
  int get constantRateFactor {
    switch (outputQuality) {
      case OutputQuality.lossless:
        return 0;
      case OutputQuality.ultraHigh:
        return 16;
      case OutputQuality.high:
        return 18;
      case OutputQuality.mediumHigh:
        return 20;
      case OutputQuality.medium:
        return 23;
      case OutputQuality.mediumLow:
        return 26;
      case OutputQuality.low:
        return 28;
      case OutputQuality.veryLow:
        return 32;
      case OutputQuality.potato:
        return 51;
    }
  }
}

/// Supported video output formats for export.
///
/// These formats are passed to FFmpeg using the appropriate container flags.
/// The compatibility of each format may vary by platform and codec support.
enum VideoOutputFormat {
  /// MPEG-4 Part 14, widely supported.
  mp4,

  /// QuickTime Movie format, common on Apple devices.
  mov,

  /// WebM format, optimized for web use.
  webm,

  /// Matroska format, flexible and open standard.
  mkv,

  /// Audio Video Interleave, a legacy format with wide support.
  avi,

  /// Graphics Interchange Format, used for short animations.
  gif,
}

/// Describes the desired output quality for exported videos.
///
/// Internally, this is mapped to FFmpeg's `-crf` (Constant Rate Factor) values.
/// Lower CRF means better quality and larger file size.
enum OutputQuality {
  /// 🔒 Lossless quality using `-crf 0`.
  /// Highest possible quality, but results in very large file sizes.
  lossless,

  /// 🥇 Ultra high quality using `-crf 16`.
  /// Slightly better than visually lossless; larger file size.
  ultraHigh,

  /// 🔍 High quality using `-crf 18`.
  /// Visually lossless and suitable for most high-quality exports.
  high,

  /// ✅ Good quality using `-crf 20`.
  /// Very close to high, but slightly more compressed.
  mediumHigh,

  /// ⚖️ Balanced quality using `-crf 23`.
  /// Reasonable trade-off between quality and file size (FFmpeg default).
  medium,

  /// 💡 Medium-low quality using `-crf 26`.
  /// Smaller file size with noticeable compression artifacts.
  mediumLow,

  /// 📦 Compressed quality using `-crf 28`.
  /// Suitable for quick exports or previews.
  low,

  /// 🪶 Very compressed using `-crf 32`.
  /// Lower quality, faster to process, smallest file size.
  veryLow,

  /// 🥔 Worst possible quality using `-crf 51`.
  /// Tiny file size, heavy artifacts — not recommended for final output.
  potato,
}

/// Determines the encoding speed vs. compression trade-off.
///
/// Used with FFmpeg's `-preset` option. Faster presets result in quicker
/// encoding but larger file sizes. Slower presets produce smaller files
/// but take more time.
enum EncodingPreset {
  /// 🚀 Ultrafast encoding, largest file size.
  ultrafast,

  /// ⚡ Superfast encoding.
  superfast,

  /// 🏃 Very fast encoding.
  veryfast,

  /// 🏃‍♂️ Faster encoding.
  faster,

  /// 🏎️ Fast encoding.
  fast,

  /// ⚖️ Balanced between speed and compression.
  medium,

  /// 🐢 Slower encoding, better compression.
  slow,

  /// 🐌 Very slow encoding, smaller file size.
  slower,

  /// 🧊 Extremely slow, high compression.
  veryslow,

  /// 🧪 Placebo — max compression, impractical speed.
  placebo,
}
