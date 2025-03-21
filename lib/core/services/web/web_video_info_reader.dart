import 'dart:async';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:web/web.dart' as web;

import '../../utils/web_blob_utils.dart';

class WebVideoInfoReader {
  Future<Map<String, dynamic>> processVideoWeb(
    Uint8List videoBytes, {
    String? fileName,
  }) async {
    final blob = Blob.fromUint8List(videoBytes);

    final objectUrl = web.URL.createObjectURL(blob);
    final video = web.HTMLVideoElement()
      ..src = objectUrl
      ..preload = 'metadata';

    final completer = Completer<Map<String, dynamic>>();

    void cleanup() => web.URL.revokeObjectURL(objectUrl);

    var mimeType = lookupMimeType('', headerBytes: videoBytes);
    var sp = mimeType?.split('/') ?? [];
    var format = sp.length == 2 ? sp[1] : 'mp4';

    video.onLoadedMetadata.listen((_) {
      final result = {
        'fileSize': videoBytes.length,
        'duration': video.duration * 1000, // ms
        'width': video.videoWidth,
        'height': video.videoHeight,
        'format': format,
      };
      cleanup();
      completer.complete(result);
    });

    video.onError.listen((_) {
      cleanup();
      completer.complete({'error': 'Failed to load video metadata'});
    });

    return completer.future;
  }
}
