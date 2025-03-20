import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_informations_model.dart';

import '/core/models/thumbnail/create_video_thumbnail_model.dart';
import 'pro_video_editor_method_channel.dart';

abstract class ProVideoEditorPlatform extends PlatformInterface {
  /// Constructs a ProVideoEditorPlatform.
  ProVideoEditorPlatform() : super(token: _token);

  static final Object _token = Object();

  static ProVideoEditorPlatform _instance = MethodChannelProVideoEditor();

  /// The default instance of [ProVideoEditorPlatform] to use.
  ///
  /// Defaults to [MethodChannelProVideoEditor].
  static ProVideoEditorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ProVideoEditorPlatform] when
  /// they register themselves.
  static set instance(ProVideoEditorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<VideoInformations> getVideoInformations(EditorVideo value) {
    throw UnimplementedError(
        'getVideoInformations() has not been implemented.');
  }

  Future<List<Uint8List>> createVideoThumbnails(CreateVideoThumbnail value) {
    throw UnimplementedError(
        'createVideoThumbnails() has not been implemented.');
  }
}
