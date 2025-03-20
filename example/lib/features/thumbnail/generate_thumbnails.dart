import 'package:flutter/material.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor_example/core/constants/example_constants.dart';

class GenerateThumbnails extends StatefulWidget {
  const GenerateThumbnails({super.key});

  @override
  State<GenerateThumbnails> createState() => _GenerateThumbnailsState();
}

class _GenerateThumbnailsState extends State<GenerateThumbnails> {
  final List<MemoryImage> _thumbnails = [];

  void _getVideoInformations() async {
    var informations = await VideoUtilsService.instance.getVideoInformations(
      EditorVideo(assetPath: kVideoEditorExampleAssetPath),
    );

    debugPrint(
      'The video has a duration of ${informations.duration.inMilliseconds}ms',
    );
  }

  void _generateThumbnails() async {
    await VideoUtilsService.instance.createVideoThumbnails(
      CreateVideoThumbnail(
        video: EditorVideo(assetPath: kVideoEditorExampleAssetPath),
        timestamps: [
          const Duration(seconds: 0),
          const Duration(seconds: 5),
          const Duration(seconds: 10),
          const Duration(seconds: 15),
          const Duration(seconds: 20),
        ],
        imageWidth: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnails')),
      body: ListView(
        children: [
          Center(
            child: FilledButton(
              onPressed: _getVideoInformations,
              child: const Text('Read Video informations'),
            ),
          ),
          Wrap(
            spacing: 10,
            children: _thumbnails
                .map(
                  (item) => Image(image: item),
                )
                .toList(),
          ),
          const SizedBox(height: 40),
          Center(
            child: FilledButton(
              onPressed: _generateThumbnails,
              child: const Text('Generate Thumbnails'),
            ),
          ),
        ],
      ),
    );
  }
}
