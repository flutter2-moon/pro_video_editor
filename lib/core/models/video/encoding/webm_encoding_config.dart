import 'base_encoding_config.dart';

/// Encoding configuration for exporting videos in WebM format.
///
/// Uses VP9 for video and Opus for audio by default.
/// Provides control over bitrate, threading, and performance tuning.
class WebMEncodingConfig extends VideoEncodingConfig {
  /// Creates a [WebMEncodingConfig] with optional custom settings.
  const WebMEncodingConfig({
    this.videoCodec = 'libvpx-vp9',
    this.audioCodec = 'libopus',
    this.bitrate = '1M',
    this.cpuUsed = 5,
    this.deadline = 'realtime',
    this.threads = 4,
    super.customArgs,
  });

  /// The video codec to use (default: `libvpx-vp9`).
  final String videoCodec;

  /// The audio codec to use (default: `libopus`).
  final String audioCodec;

  /// The target video bitrate (e.g., `1M` for 1 megabit per second).
  final String bitrate;

  /// The VP9 encoding speed vs. quality trade-off (0–5, higher = faster).
  final int cpuUsed;

  /// Encoding deadline preset: `best`, `good`, or `realtime`
  /// (default: `realtime`).
  final String deadline;

  /// Number of threads to use for encoding.
  final int threads;

  /// Converts the configuration into a list of FFmpeg command-line arguments.
  @override
  List<String> toFFmpegArgs() {
    return [
      /// Set video codec to VP9 for WebM
      '-c:v', videoCodec,

      /// Target video bitrate
      '-b:v', bitrate,

      /// Enable row-based multi-threading
      '-row-mt', '1',

      /// Use multiple threads for faster encoding
      '-threads', '$threads',

      /// Cpu used
      '-cpu-used', '$cpuUsed',

      /// Deadline
      '-deadline', deadline,

      /// Audio codec
      '-c:a', audioCodec,
      ...customArgs,
    ];
  }
}
