package ch.waio.pro_video_editor.video

fun mimeToExtension(mimeType: String): String {
    return when (mimeType.lowercase()) {
        "video/mp4" -> "mp4"
        "video/webm" -> "webm"
        "video/3gpp" -> "3gp"
        "video/quicktime" -> "mov"
        "video/x-msvideo" -> "avi"
        "video/x-matroska" -> "mkv"
        "video/x-ms-wmv" -> "wmv"
        "video/x-flv" -> "flv"
        "video/mpeg" -> "mpg"
        else -> "mp4"
    }
}
