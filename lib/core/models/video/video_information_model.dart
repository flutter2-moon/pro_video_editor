import 'dart:ui';

/// A class that holds metadata information about a video.
class VideoInformation {
  /// Creates a [VideoInformation] instance.
  ///
  /// - [duration]: The total playback time of the video.
  /// - [extension]: The file format of the video (e.g., "mp4", "avi").
  /// - [fileSize]: The size of the video file in bytes.
  /// - [resolution]: The width and height of the video in pixels.
  VideoInformation({
    required this.duration,
    required this.extension,
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
  final String extension;

  /// Returns a copy of this config with the given fields replaced.
  VideoInformation copyWith({
    int? fileSize,
    Size? resolution,
    Duration? duration,
    String? extension,
  }) {
    return VideoInformation(
      fileSize: fileSize ?? this.fileSize,
      resolution: resolution ?? this.resolution,
      duration: duration ?? this.duration,
      extension: extension ?? this.extension,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoInformation &&
        other.fileSize == fileSize &&
        other.resolution == resolution &&
        other.duration == duration &&
        other.extension == extension;
  }

  @override
  int get hashCode {
    return fileSize.hashCode ^
        resolution.hashCode ^
        duration.hashCode ^
        extension.hashCode;
  }
}
