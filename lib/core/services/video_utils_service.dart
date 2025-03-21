import 'dart:typed_data';

import 'package:pro_video_editor/core/models/thumbnail/create_video_thumbnail_model.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_information_model.dart';
import 'package:pro_video_editor/pro_video_editor_platform_interface.dart';

class VideoUtilsService {
  VideoUtilsService._();

  /// The singleton instance of `VideoUtilsService`.
  static final VideoUtilsService instance = VideoUtilsService._();

  Future<String?> getPlatformVersion() {
    return ProVideoEditorPlatform.instance.getPlatformVersion();
  }

  Future<VideoInformation> getVideoInformation(EditorVideo value) {
    return ProVideoEditorPlatform.instance.getVideoInformation(value);
  }

  Future<List<Uint8List>> createVideoThumbnails(CreateVideoThumbnail value) {
    return ProVideoEditorPlatform.instance.createVideoThumbnails(value);
  }
}
