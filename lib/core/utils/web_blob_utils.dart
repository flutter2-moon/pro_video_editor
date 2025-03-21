import 'dart:js_interop';
import 'dart:typed_data';

@JS('Blob')
extension type Blob._(JSObject _) implements JSObject {
  external factory Blob(JSArray<JSArrayBuffer> blobParts, JSObject? options);

  factory Blob.fromBytes(List<int> bytes) {
    final data = Uint8List.fromList(bytes).buffer.toJS;
    return Blob([data].toJS, null);
  }
  factory Blob.fromUint8List(Uint8List bytes) {
    final data = Uint8List.fromList(bytes).buffer.toJS;
    return Blob([data].toJS, null);
  }
  @JS('type')
  external String get type;

  external JSArrayBuffer? get blobParts;
  external JSObject? get options;
}
