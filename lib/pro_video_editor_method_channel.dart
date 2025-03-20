import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '/core/models/video/editor_video_model.dart';
import '/core/models/video/video_informations_model.dart';
import 'core/models/thumbnail/create_video_thumbnail_model.dart';
import 'pro_video_editor_platform_interface.dart';

/// An implementation of [ProVideoEditorPlatform] that uses method channels.
class MethodChannelProVideoEditor extends ProVideoEditorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pro_video_editor');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<VideoInformations> getVideoInformations(EditorVideo value) async {
    final response = await methodChannel
            .invokeMethod<Map<dynamic, dynamic>>('getVideoInformations') ??
        {};
    return VideoInformations(
      duration: response['duration'] ?? Duration.zero,
    );
  }

  @override
  Future<List<Uint8List>> createVideoThumbnails(
      CreateVideoThumbnail value) async {
    final thumbnails = await methodChannel
        .invokeMethod<List<Uint8List>>('createVideoThumbnails');
    return thumbnails ?? [];
  }
}
