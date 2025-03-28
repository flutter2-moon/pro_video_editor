import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos as animated GIFs.
///
/// Controls frame rate, output width, scaling algorithm, and loop behavior.
/// Designed for small, looping clips with acceptable quality and file size.
class GifEncodingConfig extends VideoEncodingConfig {
  /// Creates a [GifEncodingConfig] with optional custom settings.
  const GifEncodingConfig({
    this.loop = 0,
  });

  /// Loop count for the GIF (0 = infinite loop).
  final int loop;

  @override
  List<String> toFFmpegArgs([bool enableAudio = false]) {
    return [
      '-loop',
      '$loop',
      ...customArgs,
    ];
  }

  /// Returns a copy of this config with the given fields replaced.
  GifEncodingConfig copyWith({
    int? loop,
  }) {
    return GifEncodingConfig(
      loop: loop ?? this.loop,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GifEncodingConfig && other.loop == loop;
  }

  @override
  int get hashCode => loop.hashCode;
}
