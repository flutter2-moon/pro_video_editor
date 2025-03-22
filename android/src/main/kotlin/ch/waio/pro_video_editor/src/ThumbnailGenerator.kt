// =======================
// ThumbnailGenerator.kt
// =======================

package ch.waio.pro_video_editor.src

import android.content.Context
import android.media.MediaMetadataRetriever
import android.util.Log
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream

class ThumbnailGenerator(private val context: Context) {

    suspend fun generateThumbnails(
        videoBytes: ByteArray,
        timestamps: List<Long>,
        thumbnailFormat: String,
        extension: String,
        width: Int
    ): List<ByteArray> = withContext(Dispatchers.IO) {
        val TAG = "FFmpegThumbnailGen"
        val tempVideoFile = writeBytesToTempFile(videoBytes, extension)
        val thumbnails = MutableList<ByteArray?>(timestamps.size) { null }

        val jobs = timestamps.mapIndexed { index, timeMs ->
            async {
                val startTime = System.currentTimeMillis()
                val tempImageFile =
                    File.createTempFile("thumb_$index", ".$thumbnailFormat", context.cacheDir)
                val timestampStr = String.format("%.3f", timeMs / 1000.0)

                val command =
                    "-y -ss $timestampStr -i ${tempVideoFile.absolutePath} -vframes 1 -vf scale=$width:-2 ${tempImageFile.absolutePath}"
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


    private fun writeBytesToTempFile(bytes: ByteArray, extension: String): File {
        val tempFile = File.createTempFile("video_temp", ".$extension", context.cacheDir)
        FileOutputStream(tempFile).use {
            it.write(bytes)
        }
        return tempFile
    }
}
