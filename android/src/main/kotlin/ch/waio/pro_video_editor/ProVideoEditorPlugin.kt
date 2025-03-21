package ch.waio.pro_video_editor

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import ch.waio.pro_video_editor.src.VideoProcessor
import ch.waio.pro_video_editor.src.ThumbnailGenerator
import kotlinx.coroutines.*

/** ProVideoEditorPlugin */
class ProVideoEditorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var videoProcessor: VideoProcessor
    private lateinit var thumbnailGenerator: ThumbnailGenerator
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

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
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val extension = call.argument<String>("extension")

                if (videoBytes != null && extension != null) {
                    val info = videoProcessor.processVideo(videoBytes, extension)
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
                val extension = call.argument<String>("extension")

                val timestamps = rawTimestamps?.map { it.toLong() }

                if (videoBytes == null || timestamps == null || thumbnailFormat == null || imageWidth == null || extension == null) {
                    result.error("INVALID_ARGUMENTS", "Missing or invalid arguments", null)
                    return
                }

                coroutineScope.launch {
                    try {
                        val thumbnails = thumbnailGenerator.generateThumbnails(
                            videoBytes = videoBytes,
                            timestamps = timestamps,
                            extension = extension,
                            thumbnailFormat = thumbnailFormat,
                            width = imageWidth
                        )

                        withContext(Dispatchers.Main) {
                            result.success(thumbnails)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("THUMBNAIL_ERROR", e.message, null)
                        }
                    }
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        coroutineScope.cancel()
    }
}
