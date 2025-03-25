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
    required this.devicePixelRatio,
    this.outputQuality = OutputQuality.medium,
    this.encodingPreset = EncodingPreset.fast,
    this.startTime,
    this.endTime,
    this.blur = 1,
    this.colorFilters = const [],
  }) : assert(
          startTime == null || endTime == null || startTime < endTime,
          'startTime must be before endTime',
        );

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

  /// The timestamp where the export should begin, if trimming is needed.
  ///
  /// If null, the export will start from the beginning of the video.
  final Duration? startTime;

  /// The timestamp where the export should end, if trimming is needed.
  ///
  /// If null, the export will continue to the end of the video.
  final Duration? endTime;

  final List<List<num>> colorFilters;

  final double blur;
  final double devicePixelRatio;

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

  double get adaptiveKernelMultiplier {
    if (blur < 5) return 1.2;
    if (blur < 15) return 1.35;
    if (blur < 30) return 1.4;
    return 1.5;
  }

  String get complexFilter {
    final ffmpegSigma = blur * devicePixelRatio * adaptiveKernelMultiplier;
    return 'gblur=sigma=$ffmpegSigma';
  }

  String get _colorFilters {
    if (colorFilters.isEmpty) return '';

    for (final matrix in colorFilters) {
      if (matrix.length != 20) {
        throw ArgumentError('Each color matrix must have exactly 20 values.');
      }
    }

    // Merge all matrices
    List<double> merged =
        List.from(colorFilters.first.map((e) => e.toDouble()));
    for (int m = 1; m < colorFilters.length; m++) {
      final a = merged;
      final b = colorFilters[m].map((e) => e.toDouble()).toList();
      final result = List<double>.filled(20, 0.0);
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 5; col++) {
          double sum = 0.0;
          for (int i = 0; i < 4; i++) {
            sum += a[row * 5 + i] * b[i * 5 + col];
          }
          if (col == 4) sum += a[row * 5 + 4];
          result[row * 5 + col] = sum;
        }
      }
      merged = result;
    }

    String expr(double r, double g, double b, double a, double bias) {
      final e = '${r}*r(X,Y)+${g}*g(X,Y)+${b}*b(X,Y)+${a}*a(X,Y)+$bias';
      return 'clip($e,0,255)';
    }

    final rExpr = expr(merged[0], merged[1], merged[2], merged[3], merged[4]);
    final gExpr = expr(merged[5], merged[6], merged[7], merged[8], merged[9]);
    final bExpr =
        expr(merged[10], merged[11], merged[12], merged[13], merged[14]);

    // Wrap expressions in single quotes (FFmpeg wants that for complex math)
    return "geq=r='$rExpr':g='$gExpr':b='$bExpr'";
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
