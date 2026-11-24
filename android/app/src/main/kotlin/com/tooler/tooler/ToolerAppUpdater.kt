package com.tooler.tooler

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * TOOLER IN-APP GITHUB APK UPDATER
 * ---------------------------------------------------------------------------
 * - Resolves latest Tooler.apk from https://github.com/AyushHarinkhede/Tooler
 *   (GitHub Releases latest asset or main branch raw file)
 * - Streams real-time download progress (%) & byte counts to Flutter
 * - Verifies downloaded APK ZIP header (PK) before removing older Tooler*.apk
 * - Deletes previous Tooler.apk files in app updates & public Downloads/Tooler
 *   and saves the fresh Tooler.apk cleanly
 * - Checks official Android unknown-app install permission and launches the
 *   Android system Package Installer UI so the user can install/replace in-place
 */
class ToolerAppUpdater(private val context: Context) {

    companion object {
        private const val REPO_OWNER = "AyushHarinkhede"
        private const val REPO_NAME = "Tooler"
        private const val APK_FILE_NAME = "Tooler.apk"
        private const val LATEST_RELEASE_API = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
        private val RAW_CANDIDATE_URLS = listOf(
            "https://github.com/$REPO_OWNER/$REPO_NAME/raw/main/$APK_FILE_NAME",
            "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/$APK_FILE_NAME",
            "https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/$APK_FILE_NAME"
        )
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val isBusy = AtomicBoolean(false)

    @Volatile
    var progressSink: EventChannel.EventSink? = null

    @Volatile
    var pendingInstallApkPath: String? = null

    private fun emitState(
        status: String,
        progress: Double = 0.0,
        receivedBytes: Long = 0L,
        totalBytes: Long = -1L,
        message: String = "",
        apkPath: String = ""
    ) {
        val sink = progressSink ?: return
        mainHandler.post {
            try {
                sink.success(
                    mapOf(
                        "status" to status,
                        "progress" to progress.coerceIn(0.0, 1.0),
                        "receivedBytes" to receivedBytes,
                        "totalBytes" to totalBytes,
                        "message" to message,
                        "apkPath" to apkPath
                    )
                )
            } catch (_: Exception) {
            }
        }
    }

    fun getCurrentVersionInfo(): Map<String, Any> {
        return try {
            val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(
                    context.packageName,
                    android.content.pm.PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(context.packageName, 0)
            }
            val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pkgInfo.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                pkgInfo.versionCode.toLong()
            }
            mapOf(
                "versionName" to (pkgInfo.versionName ?: "1.0.45"),
                "versionCode" to code,
                "canInstallPackages" to canInstallUnknownPackages()
            )
        } catch (_: Exception) {
            mapOf(
                "versionName" to "1.0.45",
                "versionCode" to 36001L,
                "canInstallPackages" to canInstallUnknownPackages()
            )
        }
    }

    fun canInstallUnknownPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                context.packageManager.canRequestPackageInstalls()
            } catch (_: Exception) {
                false
            }
        } else {
            true
        }
    }

    fun openInstallPermissionSettings(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}")
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                true
            } else {
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    fun startUpdateFromGithub() {
        if (!isBusy.compareAndSet(false, true)) return

        thread(name = "ToolerAppUpdater", isDaemon = true) {
            var tempFile: File? = null
            try {
                emitState(
                    status = "checking",
                    progress = 0.02,
                    message = "Connecting to GitHub repository..."
                )

                val downloadUrl = resolveLatestApkUrl()
                    ?: throw IllegalStateException(
                        "Tooler.apk was not found in github.com/$REPO_OWNER/$REPO_NAME (main branch or Releases). Push Tooler.apk or attach it to a Release first."
                    )

                emitState(
                    status = "downloading",
                    progress = 0.04,
                    message = "Downloading latest Tooler.apk..."
                )

                val updatesDir = getUpdatesDirectory()
                tempFile = File(updatesDir, "Tooler.apk.part")
                if (tempFile.exists()) tempFile.delete()

                val conn = openWithRedirects(downloadUrl, "GET")
                val code = conn.responseCode
                if (code !in 200..299) {
                    conn.disconnect()
                    throw IllegalStateException("GitHub download returned HTTP $code")
                }

                val mime = conn.contentType?.lowercase(Locale.ROOT) ?: ""
                if (mime.contains("text/html")) {
                    conn.disconnect()
                    throw IllegalStateException("GitHub returned a web page instead of Tooler.apk")
                }

                val totalBytes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    conn.contentLengthLong
                } else {
                    conn.contentLength.toLong()
                }

                var received = 0L
                var lastEmitMs = 0L
                try {
                    BufferedInputStream(conn.inputStream, 32768).use { input ->
                        FileOutputStream(tempFile).use { output ->
                            val buf = ByteArray(16384)
                            var n: Int
                            while (input.read(buf).also { n = it } != -1) {
                                output.write(buf, 0, n)
                                received += n
                                val now = System.currentTimeMillis()
                                if (now - lastEmitMs >= 80L) {
                                    lastEmitMs = now
                                    val prog = if (totalBytes > 0L) {
                                        (0.05 + (received.toDouble() / totalBytes.toDouble()) * 0.87)
                                            .coerceIn(0.05, 0.92)
                                    } else {
                                        0.50
                                    }
                                    emitState(
                                        status = "downloading",
                                        progress = prog,
                                        receivedBytes = received,
                                        totalBytes = totalBytes,
                                        message = "Downloading latest Tooler.apk..."
                                    )
                                }
                            }
                            output.flush()
                        }
                    }
                } finally {
                    conn.disconnect()
                }

                // Verify the downloaded file is a valid APK (ZIP magic bytes PK\x03\x04)
                if (!isValidApkFile(tempFile)) {
                    throw IllegalStateException("Downloaded file is not a valid Android APK package")
                }

                emitState(
                    status = "replacing",
                    progress = 0.94,
                    receivedBytes = received,
                    totalBytes = received,
                    message = "Replacing previous Tooler.apk on device..."
                )

                // Delete older Tooler*.apk files before installing the fresh APK
                deleteOldApkFiles(updatesDir, excludeFile = tempFile)

                val finalApk = File(updatesDir, APK_FILE_NAME)
                if (finalApk.exists()) finalApk.delete()
                if (!tempFile.renameTo(finalApk)) {
                    tempFile.copyTo(finalApk, overwrite = true)
                    tempFile.delete()
                }

                // Also replace Tooler.apk in Downloads/Tooler so the user's Downloads stays fresh
                mirrorToDownloadsFolder(finalApk)

                pendingInstallApkPath = finalApk.absolutePath

                emitState(
                    status = "ready",
                    progress = 0.98,
                    receivedBytes = received,
                    totalBytes = received,
                    message = "Opening Android installer...",
                    apkPath = finalApk.absolutePath
                )

                // Trigger system package installer (or request Install Unknown Apps permission first)
                mainHandler.post {
                    triggerSystemInstallInternal(finalApk, received)
                }
            } catch (e: Exception) {
                if (tempFile != null && tempFile.exists()) {
                    try { tempFile.delete() } catch (_: Exception) {}
                }
                emitState(
                    status = "error",
                    progress = 0.0,
                    message = e.message ?: "Update failed"
                )
            } finally {
                isBusy.set(false)
            }
        }
    }

    fun launchPendingInstall(): Boolean {
        val path = pendingInstallApkPath
        val file = if (!path.isNullOrBlank()) {
            File(path)
        } else {
            File(getUpdatesDirectory(), APK_FILE_NAME)
        }
        if (!file.exists() || !isValidApkFile(file)) return false
        return triggerSystemInstallInternal(file, file.length())
    }

    private fun triggerSystemInstallInternal(apkFile: File, sizeBytes: Long): Boolean {
        if (!canInstallUnknownPackages()) {
            emitState(
                status = "needs_permission",
                progress = 1.0,
                receivedBytes = sizeBytes,
                totalBytes = sizeBytes,
                message = "Allow 'Install unknown apps' for Tooler to apply the update.",
                apkPath = apkFile.absolutePath
            )
            openInstallPermissionSettings()
            return false
        }

        return try {
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                apkFile
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(intent)
            emitState(
                status = "installing",
                progress = 1.0,
                receivedBytes = sizeBytes,
                totalBytes = sizeBytes,
                message = "System installer opened — tap Update to install.",
                apkPath = apkFile.absolutePath
            )
            true
        } catch (e: Exception) {
            emitState(
                status = "error",
                progress = 0.0,
                message = "Unable to launch system installer: ${e.message ?: "Unknown error"}"
            )
            false
        }
    }

    private fun resolveLatestApkUrl(): String? {
        // 1. Check GitHub Releases API for Tooler.apk or any .apk asset
        try {
            val apiConn = openWithRedirects(LATEST_RELEASE_API, "GET", accept = "application/vnd.github+json")
            try {
                if (apiConn.responseCode in 200..299) {
                    val body = apiConn.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(body)
                    val assets = json.optJSONArray("assets")
                    if (assets != null) {
                        var fallbackApkUrl: String? = null
                        for (i in 0 until assets.length()) {
                            val item = assets.optJSONObject(i) ?: continue
                            val name = item.optString("name", "")
                            val dlUrl = item.optString("browser_download_url", "")
                            if (name.equals(APK_FILE_NAME, ignoreCase = true) && dlUrl.isNotBlank()) {
                                return dlUrl
                            }
                            if (name.endsWith(".apk", ignoreCase = true) && dlUrl.isNotBlank() && fallbackApkUrl == null) {
                                fallbackApkUrl = dlUrl
                            }
                        }
                        if (fallbackApkUrl != null) return fallbackApkUrl
                    }
                }
            } finally {
                apiConn.disconnect()
            }
        } catch (_: Exception) {
        }

        // 2. Fallback to raw repository URLs on main branch / latest download redirect
        for (candidate in RAW_CANDIDATE_URLS) {
            if (probeApkUrl(candidate)) {
                return candidate
            }
        }
        return null
    }

    private fun probeApkUrl(urlStr: String): Boolean {
        return try {
            val conn = openWithRedirects(urlStr, "HEAD")
            try {
                val code = conn.responseCode
                val mime = conn.contentType?.lowercase(Locale.ROOT) ?: ""
                code in 200..299 && !mime.contains("text/html")
            } finally {
                conn.disconnect()
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun openWithRedirects(
        startUrl: String,
        method: String,
        accept: String = "*/*"
    ): HttpURLConnection {
        var current = startUrl
        var redirects = 0
        while (redirects < 8) {
            val conn = (URL(current).openConnection() as HttpURLConnection).apply {
                requestMethod = method
                instanceFollowRedirects = false
                connectTimeout = 15000
                readTimeout = 30000
                setRequestProperty("User-Agent", "Tooler-App-Updater/1.0")
                setRequestProperty("Accept", accept)
            }
            val code = conn.responseCode
            if (code == 301 || code == 302 || code == 303 || code == 307 || code == 308) {
                val loc = conn.getHeaderField("Location")
                conn.disconnect()
                if (loc.isNullOrBlank()) throw IllegalStateException("Redirect missing Location header")
                current = URI(current).resolve(loc).toString()
                redirects++
            } else {
                return conn
            }
        }
        throw IllegalStateException("Too many redirects while contacting GitHub")
    }

    private fun getUpdatesDirectory(): File {
        val base = context.getExternalFilesDir("updates") ?: File(context.filesDir, "updates")
        if (!base.exists()) base.mkdirs()
        return base
    }

    private fun isValidApkFile(file: File): Boolean {
        if (!file.exists() || file.length() < 65536L) return false
        return try {
            FileInputStream(file).use { fis ->
                val magic = ByteArray(4)
                val read = fis.read(magic)
                read == 4 && magic[0] == 0x50.toByte() && magic[1] == 0x4B.toByte()
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun deleteOldApkFiles(updatesDir: File, excludeFile: File?) {
        try {
            updatesDir.listFiles()?.forEach { f ->
                if (f != excludeFile && f.name.endsWith(".apk", ignoreCase = true)) {
                    f.delete()
                }
            }
        } catch (_: Exception) {
        }

        // Remove older Tooler*.apk copies from Downloads via MediaStore (per-row safe deletion)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val resolver = context.contentResolver
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
                val args = arrayOf("Tooler%.apk")
                resolver.query(MediaStore.Downloads.EXTERNAL_CONTENT_URI, projection, selection, args, null)?.use { cursor ->
                    val idCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(idCol)
                        val rowUri = ContentUris.withAppendedId(MediaStore.Downloads.EXTERNAL_CONTENT_URI, id)
                        try {
                            resolver.delete(rowUri, null, null)
                        } catch (_: Exception) {
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }

        // Also clean direct Downloads/Tooler or Downloads files when storage access permits
        try {
            val dlDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val toolerDl = File(dlDir, "Tooler")
            listOf(toolerDl, dlDir).forEach { dir ->
                if (dir.exists() && dir.isDirectory) {
                    dir.listFiles()?.forEach { f ->
                        if (f.isFile && f.name.startsWith("Tooler", ignoreCase = true) && f.name.endsWith(".apk", ignoreCase = true)) {
                            try { f.delete() } catch (_: Exception) {}
                        }
                    }
                }
            }
        } catch (_: Exception) {
        }
    }

    private fun mirrorToDownloadsFolder(apkFile: File) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = context.contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, APK_FILE_NAME)
                    put(MediaStore.MediaColumns.MIME_TYPE, "application/vnd.android.package-archive")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Tooler")
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return
                try {
                    resolver.openOutputStream(uri)?.use { out ->
                        FileInputStream(apkFile).use { input ->
                            input.copyTo(out)
                        }
                    }
                    val done = ContentValues().apply {
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                    }
                    resolver.update(uri, done, null, null)
                } catch (_: Exception) {
                    resolver.delete(uri, null, null)
                }
            } else {
                val dlDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Tooler")
                if (!dlDir.exists()) dlDir.mkdirs()
                val dest = File(dlDir, APK_FILE_NAME)
                if (dest.exists()) dest.delete()
                apkFile.copyTo(dest, overwrite = true)
                MediaScannerConnection.scanFile(
                    context,
                    arrayOf(dest.absolutePath),
                    arrayOf("application/vnd.android.package-archive"),
                    null
                )
            }
        } catch (_: Exception) {
        }
    }
}
