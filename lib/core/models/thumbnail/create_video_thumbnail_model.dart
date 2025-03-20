import 'package:pro_video_editor/core/models/video/editor_video_model.dart';

class CreateVideoThumbnail {
  final EditorVideo video;
  final List<Duration> timestamps;
  final double imageWidth;
  final ThumbnailFormat thumbnailFormat;

  CreateVideoThumbnail({
    required this.video,
    required this.timestamps,
    required this.imageWidth,
    this.thumbnailFormat = ThumbnailFormat.jpeg,
  });
}

enum ThumbnailFormat { jpeg, png, webp }
