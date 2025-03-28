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
  List<String> toFFmpegArgs(bool enableAudio) {
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
  WebMEncodingConfig copyWith({
    String? videoCodec,
    String? audioCodec,
    String? bitrate,
    int? cpuUsed,
    String? deadline,
    int? threads,
  }) {
    return WebMEncodingConfig(
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      bitrate: bitrate ?? this.bitrate,
      cpuUsed: cpuUsed ?? this.cpuUsed,
      deadline: deadline ?? this.deadline,
      threads: threads ?? this.threads,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WebMEncodingConfig &&
        other.videoCodec == videoCodec &&
        other.audioCodec == audioCodec &&
        other.bitrate == bitrate &&
        other.cpuUsed == cpuUsed &&
        other.deadline == deadline &&
        other.threads == threads;
  }

  @override
  int get hashCode {
    return videoCodec.hashCode ^
        audioCodec.hashCode ^
        bitrate.hashCode ^
        cpuUsed.hashCode ^
        deadline.hashCode ^
        threads.hashCode;
  }
}
