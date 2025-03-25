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
        startTime: Int?,
        endTime: Int?,
        videoDuration: Int,
        constantRateFactor: Int,
        filters: String,
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

                // Color filter logic
                val filterGraph = StringBuilder()

                if (!filters.isNullOrBlank()) {
                    // Apply filters to video stream first
                    filterGraph.append("[0:v]$filters[vid];")                     // e.g. eq=..., boxblur=...
                    filterGraph.append("[1:v][vid]scale2ref=w=iw:h=ih[ovr][base];")
                    filterGraph.append("[base][ovr]overlay=0:0")
                } else {
                    // No filters, use original video
                    filterGraph.append("[1:v][0:v]scale2ref=w=iw:h=ih[ovr][base];")
                    filterGraph.append("[base][ovr]overlay=0:0")
                }
                
                val fullFilter = filterGraph.toString()

                val ffmpegCommand = mutableListOf<String>()

                // Add start and end only if provided
                startTime?.let {
                    // Trim start time (in seconds or HH:MM:SS)
                    ffmpegCommand.addAll(listOf("-ss", it.toString()))
                }

                endTime?.let {
                    // Trim end time (in seconds or HH:MM:SS)
                    ffmpegCommand.addAll(listOf("-to", it.toString()))
                }

                // TODO: Add transformations => crop, rotate, flip
                // TODO: Add filters/ tune adjustments
                // TODO: Add blur
                // TODO: Add pixelate/ blur area
                ffmpegCommand.addAll(
                    listOf(
                        // Overwrite output file if it exists
                        "-y",

                        // Input 0: the main video
                        "-i", videoFile.absolutePath,

                        // Input 1: the overlay image (e.g. a transparent PNG)
                        "-i", imageFile.absolutePath,

                        // Apply filter chain
                        "-filter_complex", fullFilter,

                        // Set the video codec to libx264 (H.264)
                        "-c:v", "libx264",

                        // Set encoding preset (affects speed vs. compression ratio)
                        "-preset", preset,

                        // Set quality using CRF (lower is better quality, 0 = lossless)
                        "-crf", constantRateFactor.toString(),

                        // Set pixel format for broad compatibility (especially for Android/iOS playback)
                        "-pix_fmt", "yuv420p",

                        // Copy the original audio stream without re-encoding
                        "-c:a", "copy",

                        // Output file path
                        outputFile.absolutePath
                    )
                )
                val commandString = ffmpegCommand.joinToString(" ")

                Log.d("ExportVideo", "Running FFmpeg command: $commandString")

                FFmpegKit.executeAsync(commandString, { session ->
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
                    val trimmedDuration = if (startTime != null && endTime != null) {
                        ((endTime - startTime) * 1000).coerceAtLeast(1)
                    } else if (startTime != null) {
                        videoDuration - startTime * 1000
                    } else if (endTime != null) {
                        endTime * 1000
                    } else {
                        videoDuration
                    }
                    
                    val time = stat.time
                    if (trimmedDuration > 0 && time > 0) {
                        val progress = time.toDouble() / trimmedDuration.toDouble()
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
