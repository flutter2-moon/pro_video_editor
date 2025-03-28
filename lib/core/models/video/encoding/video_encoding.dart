import '../export_video_model.dart';
import 'avi_encoding_config.dart';
import 'base_encoding_config.dart';
import 'gif_encoding_config.dart';
import 'mkv_encoding_config.dart';
import 'mov_encoding_config.dart';
import 'mp4_encoding_config.dart';
import 'webm_encoding_config.dart';

/// Holds encoding configurations for various video output formats.
///
/// This class provides format-specific settings (e.g., MP4, MOV, GIF)
/// and generates corresponding FFmpeg arguments.
class VideoEncoding {
  /// Creates a [VideoEncoding] with optional custom configurations for each
  /// format.
  const VideoEncoding({
    this.mp4EncodingConfig = const Mp4EncodingConfig(),
    this.movEncodingConfig = const MovEncodingConfig(),
    this.mkvEncodingConfig = const MkvEncodingConfig(),
    this.webMEncodingConfig = const WebMEncodingConfig(),
    this.gifEncodingConfig = const GifEncodingConfig(),
    this.aviEncodingConfig = const AviEncodingConfig(),
  });

  /// Encoding configuration for MP4 output.
  final Mp4EncodingConfig mp4EncodingConfig;

  /// Encoding configuration for MOV output.
  final MovEncodingConfig movEncodingConfig;

  /// Encoding configuration for MKV output.
  final MkvEncodingConfig mkvEncodingConfig;

  /// Encoding configuration for WebM output.
  final WebMEncodingConfig webMEncodingConfig;

  /// Encoding configuration for GIF output.
  final GifEncodingConfig gifEncodingConfig;

  /// Encoding configuration for AVI output.
  final AviEncodingConfig aviEncodingConfig;

  /// Returns the FFmpeg arguments for the specified [outputFormat].
  List<String> toFFmpegArgs(VideoOutputFormat outputFormat) {
    return getEncodingConfig(outputFormat).toFFmpegArgs();
  }

  /// Returns the encoding configuration matching the given [outputFormat].
  VideoEncodingConfig getEncodingConfig(VideoOutputFormat outputFormat) {
    switch (outputFormat) {
      case VideoOutputFormat.mp4:
        return mp4EncodingConfig;
      case VideoOutputFormat.mov:
        return movEncodingConfig;
      case VideoOutputFormat.mkv:
        return mkvEncodingConfig;
      case VideoOutputFormat.webm:
        return webMEncodingConfig;
      case VideoOutputFormat.avi:
        return aviEncodingConfig;
      case VideoOutputFormat.gif:
        return gifEncodingConfig;
    }
  }
}
