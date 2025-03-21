import 'dart:typed_data';
import 'dart:ui';

import 'package:pro_video_editor/core/services/web/web_thumbnail_generator.dart';

import '/core/models/thumbnail/create_video_thumbnail_model.dart';
import '/core/models/video/editor_video_model.dart';
import '/core/models/video/video_information_model.dart';
import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';
import 'web_video_info_reader.dart';

class WebManager {
  Future<VideoInformation> getVideoInformation(EditorVideo value) async {
    var sp = Stopwatch()..start();

    var result =
        await WebVideoInfoReader().processVideoWeb(await value.safeByteArray());

    print('Read time ${sp.elapsedMilliseconds}ms');
    print(result);

    return VideoInformation(
      duration: Duration(milliseconds: safeParseInt(result['duration'])),
      format: result['format'] ?? 'unknown',
      fileSize: safeParseInt(result['fileSize']),
      resolution: Size(
        safeParseDouble(result['width']),
        safeParseDouble(result['height']),
      ),
    );
  }

  Future<List<Uint8List>> createVideoThumbnails(
    CreateVideoThumbnail value,
  ) async {
    var sp = Stopwatch()..start();

    var thumbnails = await WebThumbnailGenerator().generateThumbnails(value);

    print('Read time ${sp.elapsedMilliseconds}ms');
    print(thumbnails.length);

    return thumbnails;
  }
}
