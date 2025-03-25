import 'package:flutter/services.dart';
import 'package:pro_video_editor/core/models/video/export_transform_model.dart';

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
    this.blur = 0,
    this.transform = const ExportTransform(),
    this.colorFilters = const [],
    this.customFilter = '',
  })  : assert(
          startTime == null || endTime == null || startTime < endTime,
          'startTime must be before endTime',
        ),
        assert(
          blur >= 0,
          'Blur must be greater than or equal to 0',
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

  /// A 4x5 matrix used to apply color filters (e.g., saturation, brightness).
  ///
  /// This is typically passed to FFmpeg as a color matrix filter.
  final List<List<double>> colorFilters;

  /// Amount of blur to apply (in logical pixels).
  ///
  /// Higher values result in a stronger blur effect.
  final double blur;

  /// The device pixel ratio used for rendering accuracy and scale adjustments.
  ///
  /// This helps maintain consistent visual results across screen densities.
  final double devicePixelRatio;

  /// Transformation settings like resize, rotation, offset, and flipping.
  ///
  /// Used to control how the video or image is positioned and modified during
  /// export.
  final ExportTransform transform;

  /// Optional custom FFmpeg filter string to append to the filter chain.
  ///
  /// This allows advanced users to inject their own filter logic in addition to
  /// built-in effects like blur or crop.
  final String customFilter;

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

  String get _blurFilter {
    if (blur <= 0) return '';
    double adaptiveKernelMultiplier() {
      if (blur < 5) return 1.2;
      if (blur < 15) return 1.35;
      if (blur < 30) return 1.4;
      return 1.5;
    }

    final ffmpegSigma = blur * devicePixelRatio * adaptiveKernelMultiplier();
    return 'gblur=sigma=$ffmpegSigma';
  }

  String get _cropFilter {
    // Return if there are no transformations
    if (transform == const ExportTransform()) return '';

    int? width = transform.width;
    int? height = transform.height;
    int rotateTurns = transform.rotateTurns;
    String? x = transform.x;
    String? y = transform.y;
    bool flipX = transform.flipX;
    bool flipY = transform.flipY;

    final widthExpr = width?.toString() ?? 'in_w';
    final heightExpr = height?.toString() ?? 'in_h';

    final xExpr = x ?? '(in_w-$widthExpr)/2';
    final yExpr = y ?? '(in_h-$heightExpr)/2';

    final crop = 'crop=$widthExpr:$heightExpr:$xExpr:$yExpr';

    String rotate = '';
    switch (rotateTurns % 4) {
      case 1:
        rotate = 'rotate=PI/2';
        break;
      case 2:
        rotate = 'rotate=PI';
        break;
      case 3:
        rotate = 'rotate=3*PI/2';
        break;
    }

    final flips = <String>[
      if (flipX) 'hflip',
      if (flipY) 'vflip',
    ];

    final allFilters = <String>[
      crop,
      if (rotate.isNotEmpty) rotate,
      ...flips,
    ];

    return allFilters.join(',');
  }

  String get _colorFilterMatrix {
    List<double> multiplyColorMatrices(List<double> a, List<double> b) {
      List<double> result = List.filled(20, 0.0);
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 5; col++) {
          result[row * 5 + col] = a[row * 5 + 0] * b[col + 0] +
              a[row * 5 + 1] * b[col + 5] +
              a[row * 5 + 2] * b[col + 10] +
              a[row * 5 + 3] * b[col + 15] +
              (col == 4 ? a[row * 5 + 4] : 0);
        }
      }
      return result;
    }

    final matrices = colorFilters;
    if (matrices.any((m) => m.length != 20)) {
      throw ArgumentError('Each matrix must have exactly 20 elements (4x5).');
    }

    // Identity matrix
    List<double> result = [
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];

    // Multiply matrices in reverse application order
    for (final matrix in matrices.reversed) {
      result = multiplyColorMatrices(matrix, result);
    }

    // Extract matrix components (3x3 color transformation)
    final colorMixer = <String>[
      'rr=${result[0]}',
      'rg=${result[1]}',
      'rb=${result[2]}',
      'gr=${result[5]}',
      'gg=${result[6]}',
      'gb=${result[7]}',
      'br=${result[10]}',
      'bg=${result[11]}',
      'bb=${result[12]}',
    ];

    // Format biases for LUT (4th column values)
    String formatBias(double bias) => bias >= 0 ? '+$bias' : '$bias';
    final rBias = formatBias(result[4]);
    final gBias = formatBias(result[9]);
    final bBias = formatBias(result[14]);

    // Chain filters correctly: colorchannelmixer -> lut
    return 'colorchannelmixer=${colorMixer.join(':')},'
        'lut=r=clip(val$rBias\\,0\\,255):'
        'g=clip(val$gBias\\,0\\,255):'
        'b=clip(val$bBias\\,0\\,255)';
  }

  /// Returns a combined FFmpeg complex filter string based on active filters.
  ///
  /// Includes blur and crop filters if defined. Filters are joined with a comma
  /// and empty filters are excluded.
  String get complexFilter {
    var filters = [_blurFilter, _cropFilter, _colorFilterMatrix, customFilter]
      ..removeWhere((item) => item.isEmpty);

    return filters.join(',');
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
