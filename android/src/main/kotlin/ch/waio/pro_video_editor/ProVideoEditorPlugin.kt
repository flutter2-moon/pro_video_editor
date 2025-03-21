package ch.waio.pro_video_editor

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import ch.waio.pro_video_editor.video.VideoProcessor
import ch.waio.pro_video_editor.video.ThumbnailGenerator

/** ProVideoEditorPlugin */
class ProVideoEditorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var videoProcessor: VideoProcessor
    private lateinit var thumbnailGenerator: ThumbnailGenerator

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pro_video_editor")
        channel.setMethodCallHandler(this)
        videoProcessor = VideoProcessor(flutterPluginBinding.applicationContext)
        thumbnailGenerator = ThumbnailGenerator(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "getVideoInformation" -> {
                val videoData = when (val arg = call.arguments) {
                    is ByteArray -> arg
                    is List<*> -> arg.mapNotNull {
                        when (it) {
                            is Int -> it.toByte()
                            is Byte -> it
                            else -> null
                        }
                    }.toByteArray()

                    else -> null
                }

                if (videoData != null) {
                    val info = videoProcessor.processVideo(videoData)
                    result.success(info)
                } else {
                    result.error(
                        "InvalidArgument",
                        "Expected raw Uint8List (ByteArray/List<Int>)",
                        null
                    )
                }
            }

            "createVideoThumbnails" -> {
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val rawTimestamps = call.argument<List<Number>>("timestamps")
                val thumbnailFormat = call.argument<String>("thumbnailFormat")
                val imageWidth = call.argument<Number>("imageWidth")?.toInt()

                val timestamps = rawTimestamps?.map { it.toLong() }

                if (videoBytes == null || timestamps == null || thumbnailFormat == null || imageWidth == null) {
                    result.error("INVALID_ARGUMENTS", "Missing or invalid arguments", null)
                    return
                }

                val thumbnails = thumbnailGenerator.generateThumbnails(
                    videoBytes,
                    timestamps,
                    thumbnailFormat,
                    imageWidth
                )
                result.success(thumbnails)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
