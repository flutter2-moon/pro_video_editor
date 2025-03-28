/// Abstract base class for video encoding configurations.
///
/// Subclasses must implement [toFFmpegArgs] to provide the
/// specific FFmpeg arguments required for encoding.
///
/// You can optionally pass [customArgs] to inject extra FFmpeg parameters.
abstract class VideoEncodingConfig {
  /// Creates a [VideoEncodingConfig] with optional [customArgs].
  const VideoEncodingConfig({this.customArgs = const []});

  /// Optional custom FFmpeg arguments to be appended to the end.
  final List<String> customArgs;

  /// Converts the encoding configuration into a list of FFmpeg command-line
  /// arguments, including any [customArgs] at the end.
  List<String> toFFmpegArgs();
}
