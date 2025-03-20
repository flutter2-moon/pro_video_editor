import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pro_video_editor/shared/utils/parser/double_parser.dart';
import 'package:pro_video_editor/shared/utils/parser/int_parser.dart';

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
    var sp = Stopwatch()..start();
    var videoBytes = await value.safeByteArray();

    final response = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
          'getVideoInformations',
          videoBytes,
        ) ??
        {};

    print('Read time ${sp.elapsedMilliseconds}ms');
    print(response);

    return VideoInformations(
      duration: Duration(milliseconds: safeParseInt(response['duration'])),
      format: response['format'],
      fileSize: response['fileSize'] ?? 0,
      resolution: Size(
        safeParseDouble(response['width']),
        safeParseDouble(response['height']),
      ),
    );
  }

  @override
  Future<List<Uint8List>> createVideoThumbnails(
      CreateVideoThumbnail value) async {
    var sp = Stopwatch()..start();
    var videoBytes = await value.video.safeByteArray();

    final response = await methodChannel.invokeMethod<List<Uint8List>>(
      'createVideoThumbnails',
      {
        'videoBytes': videoBytes,
        'timestamps': value.timestamps.map((el) => el.inMilliseconds).toList(),
        'imageWidth': value.imageWidth,
      },
    );

    print('Read time ${sp.elapsedMilliseconds}ms');
    print(response);
    return [];
  }
}
