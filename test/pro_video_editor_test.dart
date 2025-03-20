import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor/pro_video_editor_platform_interface.dart';
import 'package:pro_video_editor/pro_video_editor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockProVideoEditorPlatform
    with MockPlatformInterfaceMixin
    implements ProVideoEditorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ProVideoEditorPlatform initialPlatform = ProVideoEditorPlatform.instance;

  test('$MethodChannelProVideoEditor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelProVideoEditor>());
  });

  test('getPlatformVersion', () async {
    ProVideoEditor proVideoEditorPlugin = ProVideoEditor();
    MockProVideoEditorPlatform fakePlatform = MockProVideoEditorPlatform();
    ProVideoEditorPlatform.instance = fakePlatform;

    expect(await proVideoEditorPlugin.getPlatformVersion(), '42');
  });
}
