import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos as animated GIFs.
///
/// Controls frame rate, output width, scaling algorithm, and loop behavior.
/// Designed for small, looping clips with acceptable quality and file size.
class GifEncodingConfig extends VideoEncodingConfig {
  /// Creates a [GifEncodingConfig] with optional custom settings.
  const GifEncodingConfig({
    this.loop = 0,
    super.customArgs,
  });

  /// Loop count for the GIF (0 = infinite loop).
  final int loop;

  @override
  List<String> toFFmpegArgs() {
    return [
      '-loop',
      '$loop',
      ...customArgs,
    ];
  }
}
