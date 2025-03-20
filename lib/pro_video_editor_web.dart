// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import '/core/models/thumbnail/create_video_thumbnail_model.dart';
import '/core/models/video/video_informations_model.dart';
import 'core/models/video/editor_video_model.dart';
import 'pro_video_editor_platform_interface.dart';

/// A web implementation of the ProVideoEditorPlatform of the ProVideoEditor plugin.
class ProVideoEditorWeb extends ProVideoEditorPlatform {
  /// Constructs a ProVideoEditorWeb
  ProVideoEditorWeb();

  static void registerWith(Registrar registrar) {
    ProVideoEditorPlatform.instance = ProVideoEditorWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<VideoInformations> getVideoInformations(EditorVideo value) async {
    throw UnimplementedError(
        'getVideoInformations() has not been implemented.');
  }

  @override
  Future<List<Uint8List>> createVideoThumbnails(CreateVideoThumbnail value) {
    throw UnimplementedError(
        'createVideoThumbnails() has not been implemented.');
  }
}
