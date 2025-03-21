import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart';

extension CanvasToBlobFuture on HTMLCanvasElement {
  Future<Blob> toBlobAsync(String mimeType) {
    final completer = Completer<Blob>();

    // Define JS interop callback explicitly:
    final jsCallback = (JSAny? blob) {
      if (blob != null) {
        completer.complete(blob as Blob);
      } else {
        completer.completeError('toBlob failed');
      }
    }.toJS;

    toBlob(jsCallback, mimeType);

    return completer.future;
  }
}
