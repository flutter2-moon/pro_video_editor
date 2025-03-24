package ch.waio.pro_video_editor.src

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.FFmpegKitConfig
import com.arthenica.ffmpegkit.FFmpegSession
import com.arthenica.ffmpegkit.ReturnCode
import java.io.File
import java.io.FileOutputStream
import kotlinx.coroutines.*

class ExportVideo(private val context: Context) {

    fun generate(
        videoBytes: ByteArray,
        imageBytes: ByteArray,
        outputFormat: String,
        preset: String,
        videoDuration: Int,
        constantRateFactor: Int,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit,
        onProgress: ((Double) -> Unit)? = null
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val videoFile = File.createTempFile("input_video", ".mp4", context.cacheDir)
                val imageFile = File.createTempFile("overlay_image", ".png", context.cacheDir)
                val outputFile =
                    File.createTempFile("output_video", ".$outputFormat", context.cacheDir)

                videoFile.writeBytes(videoBytes)
                imageFile.writeBytes(imageBytes)

                val ffmpegCommand = listOf(
                    "-y",
                    "-i",
                    videoFile.absolutePath,
                    "-i",
                    imageFile.absolutePath,
                    "-filter_complex",
                    "[1:v][0:v]scale2ref=w=iw:h=ih[ovr][base];[base][ovr]overlay=0:0",
                    "-c:v",
                    "libx264",
                    "-preset",
                    preset,
                    "-crf",
                    constantRateFactor.toString(),
                    "-pix_fmt",
                    "yuv420p",
                    "-c:a",
                    "copy",
                    outputFile.absolutePath
                ).joinToString(" ")

                Log.d("ExportVideo", "Running FFmpeg command: $ffmpegCommand")

                FFmpegKit.executeAsync(ffmpegCommand, { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        Handler(Looper.getMainLooper()).post {
                            onSuccess(outputFile.absolutePath)
                        }
                    } else {
                        val failReason = session.failStackTrace ?: "Unknown error"
                        Handler(Looper.getMainLooper()).post {
                            onError("FFmpeg failed: $failReason")
                        }
                    }
                }, { log ->
                    Log.d("ExportVideo", log.message)
                }, { stat ->
                    val time = stat.time
                    if (videoDuration > 0 && time > 0) {
                        val progress = time.toDouble() / videoDuration.toDouble()
                        Handler(Looper.getMainLooper()).post {
                            onProgress?.invoke(progress.coerceIn(0.0, 1.0))
                        }
                    }
                })
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    onError("Exception: ${e.message}")
                }
            }
        }
    }
}
