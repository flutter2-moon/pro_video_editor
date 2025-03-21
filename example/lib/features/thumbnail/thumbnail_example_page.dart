import 'package:flutter/material.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_information_model.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor_example/core/constants/example_constants.dart';

class ThumbnailExamplePage extends StatefulWidget {
  const ThumbnailExamplePage({super.key});

  @override
  State<ThumbnailExamplePage> createState() => _ThumbnailExamplePageState();
}

class _ThumbnailExamplePageState extends State<ThumbnailExamplePage> {
  List<MemoryImage> _thumbnails = [];

  final int _exampleImageCount = 7;

  Future<VideoInformation> _getVideoInformation() async {
    var informations = await VideoUtilsService.instance.getVideoInformation(
      EditorVideo(assetPath: kVideoEditorExampleAssetPath),
    );

    return informations;
  }

  void _generateThumbnails() async {
    var totalDuration = (await _getVideoInformation()).duration;

    if (!mounted) return;

    double step = totalDuration.inMilliseconds / _exampleImageCount;

    var raw = await VideoUtilsService.instance.createVideoThumbnails(
      CreateVideoThumbnail(
        video: EditorVideo(assetPath: kVideoEditorExampleAssetPath),
        timestamps: List.generate(_exampleImageCount, (i) {
          return Duration(
            milliseconds: ((step * i) + 1).toInt(),
          );
        }),
        imageWidth: MediaQuery.sizeOf(context).width /
            _exampleImageCount *
            MediaQuery.devicePixelRatioOf(context),
      ),
    );

    _thumbnails = raw.map(MemoryImage.new).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnails')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Center(
            child: FilledButton(
              onPressed: _getVideoInformation,
              child: const Text('Log video informations'),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: FilledButton(
              onPressed: _generateThumbnails,
              child: const Text('Generate Thumbnails'),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _thumbnails
                .map(
                  (item) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Image(
                      image: item,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
