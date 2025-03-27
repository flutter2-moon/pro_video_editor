import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '../../core/constants/example_filters.dart';
import '/shared/utils/bytes_formatter.dart';
import '/shared/widgets/filter_generator.dart';

/// A page that handles the video export workflow.
///
/// This widget provides the UI and logic for exporting a video using the
/// selected settings.
class VideoExportPage extends StatefulWidget {
  /// Creates a [VideoExportPage].
  const VideoExportPage({super.key});

  @override
  State<VideoExportPage> createState() => _VideoExportPageState();
}

class _VideoExportPageState extends State<VideoExportPage> {
  late final _playerContent = Player();
  late final _controllerContent = VideoController(_playerContent);
  late final _playerPreview = Player();
  late final _controllerPreview = VideoController(_playerPreview);

  final _boundaryKey = GlobalKey();
  bool _isExporting = false;
  Uint8List? _videoBytes;

  Duration _generationTime = Duration.zero;

  double _outputVideoRatio = 1280 / 720;
  final double _blur = 10;
  final _transform = const ExportTransform();
  final List<List<double>> _colorFilters = [];
  // kBasicFilterMatrix   kComplexFilterMatrix

  @override
  void initState() {
    super.initState();
    _playerContent.open(Media('asset:///assets/demo.mp4'), play: true);
  }

  @override
  void dispose() {
    _playerContent.dispose();
    _playerPreview.dispose();
    super.dispose();
  }

  Future<Uint8List> _captureLayerContent() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context));
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _startExport() async {
    setState(() => _isExporting = true);

    var sp = Stopwatch()..start();

    final imageBytes = await _captureLayerContent();
    final videoBytes = await loadAssetImageAsUint8List('assets/demo.mp4');

    final infos = await VideoUtilsService.instance.getVideoInformation(
      EditorVideo(byteArray: videoBytes),
    );

    if (!mounted) return;

    var data = ExportVideoModel(
      videoBytes: videoBytes,
      imageBytes: imageBytes,
      outputFormat: VideoOutputFormat.mp4,
      videoDuration: infos.duration,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      // startTime: const Duration(seconds: 15),
      endTime: const Duration(seconds: 3),
      encodingPreset: EncodingPreset.ultrafast,
      // outputQuality: OutputQuality.lossless,
      blur: _blur,
      transform: _transform,
      colorFilters: _colorFilters,
    );

    final result = await VideoUtilsService.instance.exportVideo(data);

    _generationTime = sp.elapsed;

    _outputVideoRatio = (await VideoUtilsService.instance
            .getVideoInformation(EditorVideo(byteArray: result)))
        .resolution
        .aspectRatio;

    await _playerPreview.open(await Media.memory(result));
    await _playerPreview.play();

    setState(() {
      _isExporting = false;
      _videoBytes = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Export')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            _buildDemoEditorContent(),
            _buildExportButton(),
            _buildExportedVideo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoEditorContent() {
    return AspectRatio(
      aspectRatio: 1280 / 720,
      child: Stack(
        children: [
          ColorFilterGenerator(
            filters: _colorFilters,
            child: Video(controller: _controllerContent),
          ),
          IgnorePointer(
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.white.withValues(alpha: 0.0),
                ),
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 1280 / 720,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: const Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Text(
                      '🤑',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                  Center(
                    child: Text(
                      '🚀',
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Text(
                      '❤️',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    if (_isExporting) {
      return StreamBuilder<double>(
        stream: VideoUtilsService.instance.exportProgressStream,
        builder: (context, snapshot) {
          double progress = snapshot.data ?? 0;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, animatedValue, _) {
              return Column(
                spacing: 7,
                children: [
                  CircularProgressIndicator(
                    value: animatedValue,
                    // ignore: deprecated_member_use
                    year2023: false,
                  ),
                  Text('${(animatedValue * 100).toStringAsFixed(1)} / 100'),
                ],
              );
            },
          );
        },
      );
    } else {
      return ElevatedButton(
        onPressed: _startExport,
        child: const Text('Export Video'),
      );
    }
  }

  Widget _buildExportedVideo() {
    return Column(
      children: _videoBytes == null
          ? []
          : [
              AspectRatio(
                aspectRatio: _outputVideoRatio,
                child: Video(controller: _controllerPreview),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Video exported: ${formatBytes(_videoBytes!.lengthInBytes)} '
                  'bytes in ${_generationTime.inMilliseconds}ms',
                ),
              ),
            ],
    );
  }
}
