import 'dart:async';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:web/web.dart' as web;

import '../../utils/web_blob_utils.dart';

/// A utility class for reading basic video metadata in web environments.
///
/// This class uses the browser's `HTMLVideoElement` and Blob API to
/// extract metadata such as duration, dimensions, and format from a
/// video represented as [Uint8List] bytes.
class WebVideoInfoReader {
  /// Processes a video file provided as [videoBytes] and extracts metadata.
  ///
  /// Optionally accepts a [fileName] which may help determine the MIME type.
  ///
  /// Returns a [Future] containing a map with the following keys:
  /// - `fileSize`: The size of the video in bytes.
  /// - `duration`: Duration of the video in milliseconds.
  /// - `width`: Width of the video in pixels.
  /// - `height`: Height of the video in pixels.
  /// - `format`: The video format (e.g. `mp4`, `webm`).
  ///
  /// If an error occurs while loading metadata, the result will contain:
  /// - `error`: A string describing the failure.
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
