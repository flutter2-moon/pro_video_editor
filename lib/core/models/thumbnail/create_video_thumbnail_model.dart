import 'package:pro_video_editor/core/models/video/editor_video_model.dart';

class CreateVideoThumbnail {

  CreateVideoThumbnail({
    required this.video,
    required this.timestamps,
    required this.imageWidth,
    this.format = ThumbnailFormat.jpeg,
  });
  final EditorVideo video;
  final List<Duration> timestamps;
  final double imageWidth;

  /// If the format isn't supported by the platform will it fallback to the
  /// default format
  final ThumbnailFormat format;
}

enum ThumbnailFormat { jpeg, png, webp }
