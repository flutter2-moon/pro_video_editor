import 'dart:ui';

/// A class that holds metadata information about a video.
class VideoInformations {
  /// Creates a [VideoInformations] instance.
  ///
  /// - [duration]: The total playback time of the video.
  /// - [format]: The file format of the video (e.g., "mp4", "avi").
  /// - [fileSize]: The size of the video file in bytes.
  /// - [resolution]: The width and height of the video in pixels.
  VideoInformations({
    required this.duration,
    required this.format,
    required this.fileSize,
    required this.resolution,
  });

  /// The size of the video file in bytes.
  final int fileSize;

  /// The resolution of the video, represented as a [Size] object.
  ///
  /// Example:
  /// ```dart
  /// Size(1920, 1080) // Full HD resolution
  /// ```
  final Size resolution;

  /// The duration of the video.
  ///
  /// Example:
  /// ```dart
  /// Duration(seconds: 120) // 2 minutes
  /// ```
  final Duration duration;

  /// The format of the video file, such as "mp4" or "avi".
  final String format;
}
