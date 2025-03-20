
import 'pro_video_editor_platform_interface.dart';

class ProVideoEditor {
  Future<String?> getPlatformVersion() {
    return ProVideoEditorPlatform.instance.getPlatformVersion();
  }
}
