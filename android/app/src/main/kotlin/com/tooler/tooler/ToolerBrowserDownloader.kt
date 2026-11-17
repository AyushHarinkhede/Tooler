package com.tooler.tooler

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Base64
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.EventChannel
import java.io.BufferedInputStream
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.Locale
import kotlin.concurrent.thread

/**
 * TOOLER UNIVERSAL WEB MEDIA DOWNLOAD ENGINE
 * ------------------------------------------
 * - Native Android MediaStore saver (Gallery/Music/Movies/Downloads ready, zero scoped-storage crashes)
 * - Sends real WebView Cookies, Referer & User-Agent to bypass 403 CDN blocks
 * - Follows multi-hop HTTP/HTTPS redirects (301/302/303/307/308)
 * - Auto-resolves true file extension from HTTP Content-Type & Content-Disposition headers
 * - Supports data: base64 inline media & HLS (.m3u8) video stream stitching
 * - Streams real-time byte progress back to Flutter via EventChannel
 */
class ToolerBrowserDownloader(private val context: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    var progressSink: EventChannel.EventSink? = null

    private fun emitProgress(
        url: String,
        progress: Double,
        receivedBytes: Long,
        totalBytes: Long,
        status: String,
        fileName: String = "",
        savedLocation: String = "",
        error: String = ""
    ) {
        val sink = progressSink ?: return
        mainHandler.post {
            try {
                sink.success(
                    mapOf(
                        "url" to url,
                        "progress" to progress.coerceIn(0.0, 1.0),
                        "receivedBytes" to receivedBytes,
                        "totalBytes" to totalBytes,
                        "status" to status,
                        "fileName" to fileName,
                        "savedLocation" to savedLocation,
                        "error" to error
                    )
                )
            } catch (_: Exception) {
            }
        }
    }

    /**
     * Probes content-length & content-type via fast HTTP HEAD for accurate UI file sizing.
     */
    fun probeUrlMeta(
        urlStr: String,
        referer: String?,
        userAgent: String?,
        cookie: String?
    ): Map<String, Any> {
        if (urlStr.startsWith("data:")) {
            val mime = urlStr.substringAfter("data:").substringBefore(";").ifEmpty { "image/png" }
            val estBytes = ((urlStr.substringAfter(",").length * 3) / 4).toLong()
            return mapOf("sizeBytes" to estBytes, "mimeType" to mime)
        }
        var conn: HttpURLConnection? = null
        return try {
            conn = openConfiguredConnection(urlStr, "HEAD", referer, userAgent, cookie)
            val code = conn.responseCode
            if (code in 200..299) {
                val len = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) conn.contentLengthLong else conn.contentLength.toLong()
                val mime = conn.contentType?.substringBefore(";")?.trim() ?: ""
                mapOf("sizeBytes" to len.coerceAtLeast(0L), "mimeType" to mime)
            } else {
                mapOf("sizeBytes" to 0L, "mimeType" to "")
            }
        } catch (_: Exception) {
            mapOf("sizeBytes" to 0L, "mimeType" to "")
        } finally {
            conn?.disconnect()
        }
    }

    /**
     * Starts an async universal download for any image, video, audio, document, base64 data URI, or HLS stream.
     */
    fun startDownload(
        urlStr: String,
        suggestedName: String,
        mediaType: String,
        referer: String?,
        userAgent: String?,
        cookie: String?
    ) {
        thread(name = "ToolerWebDL", isDaemon = true) {
            try {
                emitProgress(urlStr, 0.02, 0L, -1L, "downloading", suggestedName)

                // Case 1: Inline base64 data URI (e.g. data:image/png;base64,...)
                if (urlStr.startsWith("data:", ignoreCase = true)) {
                    downloadDataUri(urlStr, suggestedName, mediaType)
                    return@thread
                }

                // Case 2: HLS .m3u8 video playlist
                val lowerUrl = urlStr.lowercase(Locale.ROOT)
                if (lowerUrl.contains(".m3u8")) {
                    downloadHlsStream(urlStr, suggestedName, referer, userAgent, cookie)
                    return@thread
                }

                // Case 3: Standard HTTP/HTTPS binary media download with redirect + cookie + header support
                val conn = openConnectionWithRedirects(urlStr, referer, userAgent, cookie)
                val code = conn.responseCode
                if (code !in 200..299) {
                    conn.disconnect()
                    emitProgress(urlStr, 0.0, 0L, 0L, "error", error = "HTTP $code")
                    return@thread
                }

                val mimeRaw = conn.contentType?.substringBefore(";")?.trim()?.lowercase(Locale.ROOT) ?: ""
                val disposition = conn.getHeaderField("Content-Disposition")
                val totalBytes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    conn.contentLengthLong
                } else {
                    conn.contentLength.toLong()
                }

                val resolvedType = resolveMediaType(mediaType, mimeRaw, urlStr)
                val finalName = resolveCleanFilename(urlStr, suggestedName, disposition, mimeRaw, resolvedType)
                val finalMime = resolveMimeType(finalName, mimeRaw, resolvedType)

                val (outStream, displayLocation, legacyFile) = openDestinationStream(finalName, finalMime, resolvedType)

                var received = 0L
                var lastEmitMs = 0L
                try {
                    BufferedInputStream(conn.inputStream, 32768).use { input ->
                        outStream.use { output ->
                            val buf = ByteArray(16384)
                            var n: Int
                            while (input.read(buf).also { n = it } != -1) {
                                output.write(buf, 0, n)
                                received += n
                                val now = System.currentTimeMillis()
                                if (now - lastEmitMs >= 90L) {
                                    lastEmitMs = now
                                    val prog = if (totalBytes > 0L) {
                                        (received.toDouble() / totalBytes.toDouble()).coerceIn(0.02, 0.99)
                                    } else {
                                        0.5
                                    }
                                    emitProgress(urlStr, prog, received, totalBytes, "downloading", finalName)
                                }
                            }
                            output.flush()
                        }
                    }
                } finally {
                    conn.disconnect()
                }

                // Trigger MediaScanner for legacy paths so Gallery/Files show it instantly
                if (legacyFile != null) {
                    try {
                        MediaScannerConnection.scanFile(
                            context,
                            arrayOf(legacyFile.absolutePath),
                            arrayOf(finalMime),
                            null
                        )
                    } catch (_: Exception) {
                    }
                }

                emitProgress(
                    url = urlStr,
                    progress = 1.0,
                    receivedBytes = received,
                    totalBytes = received,
                    status = "completed",
                    fileName = finalName,
                    savedLocation = displayLocation
                )
            } catch (e: Exception) {
                emitProgress(
                    url = urlStr,
                    progress = 0.0,
                    receivedBytes = 0L,
                    totalBytes = 0L,
                    status = "error",
                    error = e.message ?: "Download failed"
                )
            }
        }
    }

    private fun downloadDataUri(dataUri: String, suggestedName: String, mediaType: String) {
        val meta = dataUri.substringAfter("data:").substringBefore(",")
        val payload = dataUri.substringAfter(",")
        val mime = meta.substringBefore(";").ifEmpty { "image/png" }
        val isBase64 = meta.contains("base64", ignoreCase = true)
        val bytes = if (isBase64) {
            Base64.decode(payload, Base64.DEFAULT)
        } else {
            payload.toByteArray(Charsets.UTF_8)
        }

        val resolvedType = resolveMediaType(mediaType, mime, "")
        val finalName = resolveCleanFilename("", suggestedName, null, mime, resolvedType)
        val (outStream, displayLocation, legacyFile) = openDestinationStream(finalName, mime, resolvedType)

        outStream.use { it.write(bytes); it.flush() }

        if (legacyFile != null) {
            try {
                MediaScannerConnection.scanFile(context, arrayOf(legacyFile.absolutePath), arrayOf(mime), null)
            } catch (_: Exception) {
            }
        }

        emitProgress(
            url = dataUri,
            progress = 1.0,
            receivedBytes = bytes.size.toLong(),
            totalBytes = bytes.size.toLong(),
            status = "completed",
            fileName = finalName,
            savedLocation = displayLocation
        )
    }

    /**
     * Resolves an HLS (.m3u8) master/media playlist and stitches segments cleanly into a playable .ts/.mp4 video.
     */
    private fun downloadHlsStream(
        playlistUrl: String,
        suggestedName: String,
        referer: String?,
        userAgent: String?,
        cookie: String?
    ) {
        var activePlaylistUrl = playlistUrl
        var lines = fetchTextLines(activePlaylistUrl, referer, userAgent, cookie)

        // If master playlist, pick highest-bandwidth variant stream
        if (lines.any { it.startsWith("#EXT-X-STREAM-INF") }) {
            var bestBw = -1L
            var bestUri: String? = null
            for (i in lines.indices) {
                val line = lines[i].trim()
                if (line.startsWith("#EXT-X-STREAM-INF")) {
                    val bwMatch = Regex("BANDWIDTH=(\\d+)").find(line)
                    val bw = bwMatch?.groupValues?.getOrNull(1)?.toLongOrNull() ?: 0L
                    val nextUri = lines.getOrNull(i + 1)?.trim()
                    if (!nextUri.isNullOrEmpty() && !nextUri.startsWith("#") && bw >= bestBw) {
                        bestBw = bw
                        bestUri = resolveRelativeUrl(activePlaylistUrl, nextUri)
                    }
                }
            }
            if (bestUri != null) {
                activePlaylistUrl = bestUri
                lines = fetchTextLines(activePlaylistUrl, referer, userAgent, cookie)
            }
        }

        val segments = lines
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") }
            .map { resolveRelativeUrl(activePlaylistUrl, it) }

        if (segments.isEmpty()) {
            emitProgress(playlistUrl, 0.0, 0L, 0L, "error", error = "Protected or empty HLS stream")
            return
        }

        val cleanBase = suggestedName
            .replace(Regex("[\\\\/:*?\"<>|]"), "_")
            .substringBeforeLast('.')
            .ifBlank { "tooler_video_${System.currentTimeMillis()}" }
        val finalName = "$cleanBase.ts"
        val (outStream, displayLocation, legacyFile) = openDestinationStream(finalName, "video/mp2t", "video")

        var received = 0L
        outStream.use { output ->
            for ((idx, segUrl) in segments.withIndex()) {
                val segConn = openConnectionWithRedirects(segUrl, referer, userAgent, cookie)
                try {
                    if (segConn.responseCode in 200..299) {
                        segConn.inputStream.use { input ->
                            val buf = ByteArray(16384)
                            var n: Int
                            while (input.read(buf).also { n = it } != -1) {
                                output.write(buf, 0, n)
                                received += n
                            }
                        }
                    }
                } finally {
                    segConn.disconnect()
                }
                val prog = ((idx + 1).toDouble() / segments.size.toDouble()).coerceIn(0.05, 0.99)
                emitProgress(playlistUrl, prog, received, -1L, "downloading", finalName)
            }
            output.flush()
        }

        if (legacyFile != null) {
            try {
                MediaScannerConnection.scanFile(context, arrayOf(legacyFile.absolutePath), arrayOf("video/mp2t"), null)
            } catch (_: Exception) {
            }
        }

        emitProgress(
            url = playlistUrl,
            progress = 1.0,
            receivedBytes = received,
            totalBytes = received,
            status = "completed",
            fileName = finalName,
            savedLocation = displayLocation
        )
    }

    private fun fetchTextLines(url: String, referer: String?, ua: String?, cookie: String?): List<String> {
        val conn = openConnectionWithRedirects(url, referer, ua, cookie)
        return try {
            BufferedReader(InputStreamReader(conn.inputStream)).use { it.readLines() }
        } finally {
            conn.disconnect()
        }
    }

    private fun resolveRelativeUrl(base: String, relative: String): String {
        return try {
            URI(base).resolve(relative).toString()
        } catch (_: Exception) {
            relative
        }
    }

    private fun openConfiguredConnection(
        urlStr: String,
        method: String,
        referer: String?,
        userAgent: String?,
        cookie: String?
    ): HttpURLConnection {
        val conn = URL(urlStr).openConnection() as HttpURLConnection
        conn.requestMethod = method
        conn.instanceFollowRedirects = true
        conn.connectTimeout = 15000
        conn.readTimeout = 25000
        conn.setRequestProperty(
            "User-Agent",
            userAgent?.takeIf { it.isNotBlank() }
                ?: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
        )
        conn.setRequestProperty("Accept", "*/*")
        if (!referer.isNullOrBlank()) conn.setRequestProperty("Referer", referer)
        if (!cookie.isNullOrBlank()) conn.setRequestProperty("Cookie", cookie)
        return conn
    }

    private fun openConnectionWithRedirects(
        startUrl: String,
        referer: String?,
        userAgent: String?,
        cookie: String?
    ): HttpURLConnection {
        var current = startUrl
        var redirects = 0
        while (redirects < 6) {
            val conn = openConfiguredConnection(current, "GET", referer, userAgent, cookie)
            conn.instanceFollowRedirects = false
            val code = conn.responseCode
            if (code == 301 || code == 302 || code == 303 || code == 307 || code == 308) {
                val loc = conn.getHeaderField("Location")
                conn.disconnect()
                if (loc.isNullOrBlank()) throw Exception("Redirect missing Location")
                current = resolveRelativeUrl(current, loc)
                redirects++
            } else {
                return conn
            }
        }
        throw Exception("Too many redirects")
    }

    private fun openDestinationStream(
        fileName: String,
        mimeType: String,
        mediaType: String
    ): Triple<OutputStream, String, File?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            val (collection, relPath) = when (mediaType) {
                "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI to "${Environment.DIRECTORY_PICTURES}/Tooler"
                "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI to "${Environment.DIRECTORY_MOVIES}/Tooler"
                "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI to "${Environment.DIRECTORY_MUSIC}/Tooler"
                else -> MediaStore.Downloads.EXTERNAL_CONTENT_URI to "${Environment.DIRECTORY_DOWNLOADS}/Tooler"
            }

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relPath)
            }
            val uri = resolver.insert(collection, values)
                ?: throw Exception("Unable to create MediaStore entry")
            val stream = resolver.openOutputStream(uri)
                ?: throw Exception("Unable to open destination stream")
            return Triple(stream, "$relPath/$fileName", null)
        } else {
            val dirType = when (mediaType) {
                "image" -> Environment.DIRECTORY_PICTURES
                "video" -> Environment.DIRECTORY_MOVIES
                "audio" -> Environment.DIRECTORY_MUSIC
                else -> Environment.DIRECTORY_DOWNLOADS
            }
            val baseDir = Environment.getExternalStoragePublicDirectory(dirType)
            val folder = File(baseDir, "Tooler")
            if (!folder.exists()) folder.mkdirs()
            val outFile = File(folder, fileName)
            return Triple(FileOutputStream(outFile), outFile.absolutePath, outFile)
        }
    }

    private fun resolveMediaType(hint: String, mime: String, url: String): String {
        if (mime.startsWith("video/")) return "video"
        if (mime.startsWith("audio/")) return "audio"
        if (mime.startsWith("image/")) return "image"
        val lower = url.lowercase(Locale.ROOT)
        if (Regex("\\.(mp4|webm|mkv|mov|avi|m3u8|ts)(\\?.*)?$").containsMatchIn(lower)) return "video"
        if (Regex("\\.(mp3|m4a|wav|ogg|aac|flac|opus)(\\?.*)?$").containsMatchIn(lower)) return "audio"
        if (Regex("\\.(jpg|jpeg|png|webp|gif|bmp|avif|svg)(\\?.*)?$").containsMatchIn(lower)) return "image"
        return hint.ifBlank { "file" }
    }

    private fun resolveCleanFilename(
        url: String,
        suggested: String,
        disposition: String?,
        mime: String,
        mediaType: String
    ): String {
        // 1. Try Content-Disposition filename
        if (!disposition.isNullOrBlank()) {
            val m = Regex("filename\\*?=(?:UTF-8''|\"?)([^\";\\r\\n]+)\"?", RegexOption.IGNORE_CASE).find(disposition)
            val dispName = m?.groupValues?.getOrNull(1)?.trim()
            if (!dispName.isNullOrBlank()) {
                return sanitizeFilename(dispName)
            }
        }

        // 2. Try URL path segment
        var baseName = ""
        if (url.isNotBlank() && !url.startsWith("data:")) {
            try {
                val path = URI(url).path ?: ""
                val seg = path.substringAfterLast('/').trim()
                if (seg.isNotEmpty() && seg.length <= 90) baseName = seg
            } catch (_: Exception) {
            }
        }
        if (baseName.isEmpty() || baseName.equals("download", ignoreCase = true) || !baseName.contains('.')) {
            val cleanSug = suggested.replace(Regex("[\\\\/:*?\"<>|\\s]+"), "_").trim('_')
            baseName = if (cleanSug.isNotEmpty() && cleanSug.length <= 60) {
                cleanSug
            } else {
                "tooler_${mediaType}_${System.currentTimeMillis()}"
            }
        }

        baseName = sanitizeFilename(baseName)
        val hasValidExt = Regex("\\.[a-zA-Z0-9]{2,5}$").containsMatchIn(baseName)
        if (!hasValidExt) {
            val extFromMime = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
            val ext = extFromMime ?: when (mediaType) {
                "video" -> "mp4"
                "audio" -> "mp3"
                "image" -> "jpg"
                else -> "bin"
            }
            baseName = "$baseName.$ext"
        }
        return baseName
    }

    private fun resolveMimeType(fileName: String, rawMime: String, mediaType: String): String {
        if (rawMime.isNotBlank() && rawMime != "application/octet-stream") return rawMime
        val ext = fileName.substringAfterLast('.', "").lowercase(Locale.ROOT)
        val fromExt = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
        if (!fromExt.isNullOrBlank()) return fromExt
        return when (mediaType) {
            "video" -> "video/mp4"
            "audio" -> "audio/mpeg"
            "image" -> "image/jpeg"
            else -> "application/octet-stream"
        }
    }

    private fun sanitizeFilename(raw: String): String {
        val cleaned = raw.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim()
        return if (cleaned.length > 90) {
            val ext = cleaned.substringAfterLast('.', "")
            val stem = cleaned.substringBeforeLast('.').take(78)
            if (ext.isNotEmpty() && ext.length <= 5) "$stem.$ext" else cleaned.take(86)
        } else {
            cleaned.ifEmpty { "tooler_file_${System.currentTimeMillis()}" }
        }
    }
}
