import 'dart:typed_data';

import 'package:pro_video_editor/core/models/thumbnail/export_video_model.dart';

import '/core/models/thumbnail/create_video_thumbnail_model.dart';
import '/core/models/video/editor_video_model.dart';
import '/core/models/video/video_information_model.dart';
import '/pro_video_editor_platform_interface.dart';

/// A utility service for video-related operations.
///
/// This service provides a singleton interface for accessing platform-level
/// functionality such as retrieving video metadata and generating thumbnails.
class VideoUtilsService {
  /// Private constructor for singleton pattern.
  VideoUtilsService._();

  /// The singleton instance of [VideoUtilsService].
  static final VideoUtilsService instance = VideoUtilsService._();

  /// Gets the platform version from the underlying implementation.
  ///
  /// Useful for debugging or displaying platform-specific information.
  Future<String?> getPlatformVersion() {
    return ProVideoEditorPlatform.instance.getPlatformVersion();
  }

  /// Retrieves detailed information about the given video.
  ///
  /// [value] is an [EditorVideo] instance that can point to a file, memory,
  /// network URL, or asset.
  ///
  /// Returns a [Future] containing [VideoInformation] about the video.
  Future<VideoInformation> getVideoInformation(EditorVideo value) {
    return ProVideoEditorPlatform.instance.getVideoInformation(value);
  }

  /// Creates thumbnails from the given video based on the specified config.
  ///
  /// [value] is a [CreateVideoThumbnail] object that includes the video and
  /// desired timestamps and output format.
  ///
  /// Returns a [Future] containing a list of image bytes as [Uint8List].
  Future<List<Uint8List>> createVideoThumbnails(
    CreateVideoThumbnail value,
  ) {
    return ProVideoEditorPlatform.instance.createVideoThumbnails(value);
  }

  /// Exports a video using the given [value] configuration.
  ///
  /// Delegates the export to the platform-specific implementation and returns
  /// the resulting video bytes.
  Future<Uint8List> exportVideo(ExportVideoModel value) {
    return ProVideoEditorPlatform.instance.exportVideo(value);
  }

  /// A stream that emits export progress updates as a double from 0.0 to 1.0.
  ///
  /// Useful for showing progress indicators during the export process.
  Stream<double> get exportProgressStream {
    return ProVideoEditorPlatform.instance.exportProgressStream;
  }
}
