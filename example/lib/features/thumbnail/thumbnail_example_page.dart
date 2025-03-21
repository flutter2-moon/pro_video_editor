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
  VideoInformation? _informations;

  Future<void> _setVideoInformation() async {
    _informations = await VideoUtilsService.instance.getVideoInformation(
      EditorVideo(assetPath: kVideoEditorExampleAssetPath),
    );
    setState(() {});
  }

  void _generateThumbnails() async {
    await _setVideoInformation();
    var info = _informations!;
    var totalDuration = info.duration;

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
            MediaQuery.devicePixelRatioOf(context) *
            info.resolution.aspectRatio,
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
              onPressed: _setVideoInformation,
              child: const Text('Log video informations'),
            ),
          ),
          const SizedBox(height: 16),
          if (_informations != null)
            Column(
              children: [
                Text('FileSize: ${_informations!.fileSize}'),
                Text('Format: ${_informations!.extension}'),
                Text('Resolution: ${_informations!.resolution}'),
                Text('Duration: ${_informations!.duration.inMilliseconds}ms'),
              ],
            ),
          const SizedBox(height: 40),
          Center(
            child: FilledButton(
              onPressed: _generateThumbnails,
              child: const Text('Generate Thumbnails'),
            ),
          ),
          const SizedBox(height: 16),
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
