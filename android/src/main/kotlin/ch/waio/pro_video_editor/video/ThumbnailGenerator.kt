
// =======================
// ThumbnailGenerator.kt
// =======================

package ch.waio.pro_video_editor.video

import android.content.Context
import android.media.MediaMetadataRetriever
import android.util.Log
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import ch.waio.pro_video_editor.video.mimeToExtension

class ThumbnailGenerator(private val context: Context) {

    suspend fun generateThumbnails(
        videoBytes: ByteArray,
        timestamps: List<Long>,
        format: String,
        width: Int
    ): List<ByteArray> = withContext(Dispatchers.IO) {
        val TAG = "FFmpegThumbnailGen"
        val videoFormat = extractMimeType(videoBytes)?.let { mimeToExtension(it) } ?: "mp4"
        val tempVideoFile = writeBytesToTempFile(videoBytes, videoFormat)
        val thumbnails = MutableList<ByteArray?>(timestamps.size) { null }

        val jobs = timestamps.mapIndexed { index, timeMs ->
            async {
                val startTime = System.currentTimeMillis()
                val tempImageFile = File.createTempFile("thumb_$index", ".$format", context.cacheDir)
                val timestampStr = String.format("%.3f", timeMs / 1000.0)

                val command = "-y -ss $timestampStr -i ${tempVideoFile.absolutePath} -vframes 1 -vf scale=$width:-2 ${tempImageFile.absolutePath}"
                val session = FFmpegKit.execute(command)
                val duration = System.currentTimeMillis() - startTime

                if (ReturnCode.isSuccess(session.returnCode)) {
                    val bytes = tempImageFile.readBytes()
                    thumbnails[index] = bytes
                    Log.d(TAG, "[$index] ✅ $timestampStr s in $duration ms (${bytes.size} bytes)")
                } else {
                    Log.w(TAG, "[$index] ❌ Failed at $timestampStr s in $duration ms")
                }

                tempImageFile.delete()
            }
        }

        jobs.awaitAll()
        tempVideoFile.delete()
        return@withContext thumbnails.filterNotNull()
    }

    private fun extractMimeType(bytes: ByteArray): String? {
        val tempFile = writeBytesToTempFile(bytes, "tmp")
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(tempFile.absolutePath)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)
        } catch (e: Exception) {
            null
        } finally {
            retriever.release()
            tempFile.delete()
        }
    }

    private fun writeBytesToTempFile(bytes: ByteArray, format: String): File {
        val tempFile = File.createTempFile("video_temp", ".$format", context.cacheDir)
        FileOutputStream(tempFile).use {
            it.write(bytes)
        }
        return tempFile
    } 
}
