package ch.waio.pro_video_editor.video

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import android.util.Log

class ThumbnailGenerator(private val context: Context) {

    fun generateThumbnails(
        videoBytes: ByteArray,
        timestamps: List<Long>,
        format: String,
        width: Int
    ): List<ByteArray> {
        val thumbnails = mutableListOf<ByteArray>()
        val tempVideoFile = writeBytesToTempFile(videoBytes)

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(tempVideoFile.absolutePath)

            for (timeMs in timestamps) {
                val frame = retriever.getFrameAtTime(timeMs * 1000, MediaMetadataRetriever.OPTION_CLOSEST)
                if (frame != null) {
                    val scaled = Bitmap.createScaledBitmap(
                        frame,
                        width,
                        (width * frame.height) / frame.width,
                        true
                    )
                    val outputStream = ByteArrayOutputStream()
                    when (format.lowercase()) {
                        "jpeg", "jpg" -> scaled.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                        "png" -> scaled.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                        "webp" -> scaled.compress(Bitmap.CompressFormat.WEBP, 90, outputStream)
                        else -> throw IllegalArgumentException("Unsupported format: $format")
                    }
                    thumbnails.add(outputStream.toByteArray())
                    outputStream.close()
                }
            }

        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            retriever.release()
            tempVideoFile.delete() // clean up
        }

        return thumbnails
    }

    private fun writeBytesToTempFile(bytes: ByteArray): File {
        val tempFile = File.createTempFile("video_temp", ".mp4", context.cacheDir)
        FileOutputStream(tempFile).use {
            it.write(bytes)
            it.flush()
        }
        return tempFile
    }
}
