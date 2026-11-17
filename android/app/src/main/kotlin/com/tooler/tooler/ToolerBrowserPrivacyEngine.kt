package com.tooler.tooler

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.WebStorage
import androidx.webkit.ProxyConfig
import androidx.webkit.ProxyController
import androidx.webkit.WebViewFeature
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.URL
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/**
 * Native Android Browser Privacy & Real Proxy-VPN Tunnel Engine:
 * 1) Real WebView traffic routing via androidx.webkit.ProxyController (PROXY_OVERRIDE)
 * 2) Live Proxy Node discovery from GeoNode + ProxyScrape HTTPS APIs
 * 3) Parallel live HTTPS connectivity verification + real IP & Geo lookup (ipify + ipwho.is)
 * 4) True native Incognito Mode hardening via CookieManager + WebStorage purge
 */
class ToolerBrowserPrivacyEngine(private val context: Context) {

    data class VerifiedProxyNode(
        val host: String,
        val port: Int,
        val routedIp: String,
        val country: String,
        val city: String,
        val countryCode: String,
        val latencyMs: Long,
        val sourceApi: String
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var activeNode: VerifiedProxyNode? = null
    @Volatile
    private var isVpnConnected = false
    @Volatile
    private var isIncognitoHardened = false

    /**
     * Fetches the device's genuine current public IP & country (direct connection, no fake strings).
     */
    fun fetchDirectIpInfo(): Map<String, Any> {
        return queryIpGeo(null)
    }

    /**
     * Discovers live proxy nodes from 2 open HTTPS APIs, tests them in parallel over real HTTPS,
     * and binds the fastest verified working node to Android WebView's ProxyController!
     */
    fun connectLiveVpnProxy(
        customHostPort: String?,
        onComplete: (Map<String, Any>) -> Unit
    ) {
        thread(isDaemon = true) {
            try {
                if (!WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE)) {
                    mainHandler.post {
                        onComplete(
                            mapOf(
                                "connected" to false,
                                "error" to "WebView proxy override not supported on this Android WebView version"
                            )
                        )
                    }
                    return@thread
                }

                // 1. If user supplied a custom proxy host:port, verify & apply it directly
                if (!customHostPort.isNullOrBlank() && customHostPort.contains(":")) {
                    val parts = customHostPort.trim().split(":")
                    val host = parts[0].trim()
                    val port = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: 8080
                    val verified = verifyProxyCandidate(host, port, "Custom Proxy")
                    if (verified != null) {
                        applyProxyToWebView(verified, onComplete)
                        return@thread
                    } else {
                        mainHandler.post {
                            onComplete(
                                mapOf(
                                    "connected" to false,
                                    "error" to "Custom proxy $host:$port did not respond to HTTPS verification"
                                )
                            )
                        }
                        return@thread
                    }
                }

                // 2. Fetch live proxy candidates from GeoNode API + ProxyScrape API
                val candidates = mutableListOf<Triple<String, Int, String>>()
                candidates.addAll(fetchGeoNodeCandidates())
                candidates.addAll(fetchProxyScrapeCandidates())

                // Deduplicate and shuffle slightly so Rotate IP picks fresh servers
                val unique = candidates
                    .distinctBy { "${it.first}:${it.second}" }
                    .shuffled()
                    .take(24)

                if (unique.isEmpty()) {
                    mainHandler.post {
                        onComplete(
                            mapOf(
                                "connected" to false,
                                "error" to "Proxy directory APIs unreachable — check internet connection"
                            )
                        )
                    }
                    return@thread
                }

                // 3. Test candidates concurrently (fast parallel race — pick fastest verified HTTPS tunnel!)
                val pool = Executors.newFixedThreadPool(8)
                var winner: VerifiedProxyNode? = null
                try {
                    val tasks = unique.map { (host, port, src) ->
                        Callable { verifyProxyCandidate(host, port, src) }
                    }
                    val futures = pool.invokeAll(tasks, 8, TimeUnit.SECONDS)
                    val verifiedList = mutableListOf<VerifiedProxyNode>()
                    for (f in futures) {
                        if (f.isDone && !f.isCancelled) {
                            try {
                                val res = f.get()
                                if (res != null) verifiedList.add(res)
                            } catch (_: Exception) {}
                        }
                    }
                    winner = verifiedList.minByOrNull { it.latencyMs }
                } finally {
                    pool.shutdownNow()
                }

                if (winner != null) {
                    applyProxyToWebView(winner, onComplete)
                } else {
                    mainHandler.post {
                        onComplete(
                            mapOf(
                                "connected" to false,
                                "error" to "No public relay node passed live HTTPS verification — tap Retry or enter custom proxy"
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    onComplete(
                        mapOf(
                            "connected" to false,
                            "error" to (e.message ?: "VPN relay setup failed")
                        )
                    )
                }
            }
        }
    }

    private fun applyProxyToWebView(
        node: VerifiedProxyNode,
        onComplete: (Map<String, Any>) -> Unit
    ) {
        mainHandler.post {
            try {
                val proxyConfig = ProxyConfig.Builder()
                    .addProxyRule("${node.host}:${node.port}")
                    .addDirect() // Safe fallback rule if proxy drops mid-page
                    .build()

                ProxyController.getInstance().setProxyOverride(
                    proxyConfig,
                    { runnable -> runnable.run() },
                    {
                        activeNode = node
                        isVpnConnected = true
                        onComplete(
                            mapOf(
                                "connected" to true,
                                "host" to node.host,
                                "port" to node.port,
                                "ip" to node.routedIp,
                                "country" to node.country,
                                "city" to node.city,
                                "countryCode" to node.countryCode,
                                "latencyMs" to node.latencyMs,
                                "sourceApi" to node.sourceApi,
                                "protocol" to "HTTPS Proxy Tunnel (WebView ProxyController)"
                            )
                        )
                    }
                )
            } catch (e: Exception) {
                onComplete(
                    mapOf(
                        "connected" to false,
                        "error" to (e.message ?: "ProxyController error")
                    )
                )
            }
        }
    }

    fun disconnectVpnProxy(onComplete: (Boolean) -> Unit) {
        mainHandler.post {
            try {
                if (WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE)) {
                    ProxyController.getInstance().clearProxyOverride(
                        { runnable -> runnable.run() },
                        {
                            activeNode = null
                            isVpnConnected = false
                            onComplete(true)
                        }
                    )
                } else {
                    activeNode = null
                    isVpnConnected = false
                    onComplete(true)
                }
            } catch (_: Exception) {
                activeNode = null
                isVpnConnected = false
                onComplete(false)
            }
        }
    }

    fun getStatus(): Map<String, Any> {
        val n = activeNode
        return mapOf(
            "connected" to isVpnConnected,
            "incognitoHardened" to isIncognitoHardened,
            "proxyOverrideSupported" to WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE),
            "host" to (n?.host ?: ""),
            "port" to (n?.port ?: 0),
            "ip" to (n?.routedIp ?: ""),
            "country" to (n?.country ?: ""),
            "city" to (n?.city ?: ""),
            "countryCode" to (n?.countryCode ?: ""),
            "latencyMs" to (n?.latencyMs ?: 0L),
            "sourceApi" to (n?.sourceApi ?: "")
        )
    }

    /**
     * Real Native Android Incognito Hardening:
     * - When enabled: blocks persistent Chromium cookies via CookieManager.setAcceptCookie(false)
     *   and immediately purges all cookies, WebStorage (localStorage/IndexedDB), and WebView caches.
     * - When disabled: purges session remnants and restores normal cookie handling.
     */
    fun setIncognitoHardening(enabled: Boolean, onComplete: (Boolean) -> Unit) {
        mainHandler.post {
            try {
                isIncognitoHardened = enabled
                val cm = CookieManager.getInstance()
                cm.removeAllCookies {
                    try {
                        cm.removeSessionCookies(null)
                        cm.flush()
                        cm.setAcceptCookie(!enabled)
                    } catch (_: Exception) {}
                }
                WebStorage.getInstance().deleteAllData()
                purgeWebViewCacheDirs()
                onComplete(true)
            } catch (_: Exception) {
                onComplete(false)
            }
        }
    }

    fun wipeAllTracesNow(onComplete: (Boolean) -> Unit) {
        mainHandler.post {
            try {
                val cm = CookieManager.getInstance()
                cm.removeAllCookies(null)
                cm.removeSessionCookies(null)
                cm.flush()
                WebStorage.getInstance().deleteAllData()
                purgeWebViewCacheDirs()
                onComplete(true)
            } catch (_: Exception) {
                onComplete(false)
            }
        }
    }

    private fun purgeWebViewCacheDirs() {
        try {
            val cacheDirs = listOf(
                context.cacheDir.resolve("WebView"),
                context.dataDir.resolve("app_webview/Default/Cache"),
                context.dataDir.resolve("app_webview/Default/Code Cache"),
                context.dataDir.resolve("app_webview/Default/GPUCache")
            )
            for (d in cacheDirs) {
                if (d.exists()) {
                    d.listFiles()?.forEach { f ->
                        try {
                            f.deleteRecursively()
                        } catch (_: Exception) {}
                    }
                }
            }
        } catch (_: Exception) {}
    }

    // -------------------------------------------------------------------------
    // LIVE PROXY DIRECTORY APIS & VERIFICATION
    // -------------------------------------------------------------------------
    private fun fetchGeoNodeCandidates(): List<Triple<String, Int, String>> {
        val out = mutableListOf<Triple<String, Int, String>>()
        try {
            val url = URL("https://proxylist.geonode.com/api/proxy-list?limit=25&page=1&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 4500
                readTimeout = 4500
                setRequestProperty("User-Agent", "ToolerBrowser/2.0")
            }
            if (conn.responseCode == 200) {
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                val root = JSONObject(body)
                val data = root.optJSONArray("data")
                if (data != null) {
                    for (i in 0 until data.length()) {
                        val item = data.optJSONObject(i) ?: continue
                        val ip = item.optString("ip", "").trim()
                        val port = item.optString("port", "").toIntOrNull() ?: continue
                        if (ip.isNotEmpty() && port in 1..65535) {
                            out.add(Triple(ip, port, "GeoNode API"))
                        }
                    }
                }
            }
            conn.disconnect()
        } catch (_: Exception) {}
        return out
    }

    private fun fetchProxyScrapeCandidates(): List<Triple<String, Int, String>> {
        val out = mutableListOf<Triple<String, Int, String>>()
        try {
            val url = URL("https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=3500&country=all&ssl=yes&anonymity=all")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 4500
                readTimeout = 4500
                setRequestProperty("User-Agent", "ToolerBrowser/2.0")
            }
            if (conn.responseCode == 200) {
                BufferedReader(InputStreamReader(conn.inputStream)).use { br ->
                    var count = 0
                    while (count < 25) {
                        val line = br.readLine() ?: break
                        val trimmed = line.trim()
                        val parts = trimmed.split(":")
                        if (parts.size == 2) {
                            val port = parts[1].toIntOrNull()
                            if (port != null && port in 1..65535) {
                                out.add(Triple(parts[0], port, "ProxyScrape API"))
                                count++
                            }
                        }
                    }
                }
            }
            conn.disconnect()
        } catch (_: Exception) {}
        return out
    }

    private fun verifyProxyCandidate(
        host: String,
        port: Int,
        sourceApi: String
    ): VerifiedProxyNode? {
        val start = System.currentTimeMillis()
        try {
            val proxy = Proxy(Proxy.Type.HTTP, InetSocketAddress(host, port))
            val testUrl = URL("https://api.ipify.org?format=json")
            val conn = (testUrl.openConnection(proxy) as HttpURLConnection).apply {
                connectTimeout = 2800
                readTimeout = 2800
                setRequestProperty("User-Agent", "ToolerBrowser/2.0")
            }
            if (conn.responseCode == 200) {
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                conn.disconnect()
                val routedIp = JSONObject(body).optString("ip", "").trim()
                val latency = (System.currentTimeMillis() - start).coerceAtLeast(1L)
                if (routedIp.isNotEmpty()) {
                    val geo = queryGeoForIp(routedIp)
                    return VerifiedProxyNode(
                        host = host,
                        port = port,
                        routedIp = routedIp,
                        country = geo["country"] as? String ?: "Global Relay",
                        city = geo["city"] as? String ?: "",
                        countryCode = geo["countryCode"] as? String ?: "GL",
                        latencyMs = latency,
                        sourceApi = sourceApi
                    )
                }
            } else {
                conn.disconnect()
            }
        } catch (_: Exception) {}
        return null
    }

    private fun queryIpGeo(proxy: Proxy?): Map<String, Any> {
        try {
            val url = URL("https://ipwho.is/?fields=ip,country,city,country_code")
            val conn = (if (proxy != null) url.openConnection(proxy) else url.openConnection()) as HttpURLConnection
            conn.connectTimeout = 4000
            conn.readTimeout = 4000
            conn.setRequestProperty("User-Agent", "ToolerBrowser/2.0")
            if (conn.responseCode == 200) {
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                conn.disconnect()
                val obj = JSONObject(body)
                return mapOf(
                    "ip" to obj.optString("ip", ""),
                    "country" to obj.optString("country", ""),
                    "city" to obj.optString("city", ""),
                    "countryCode" to obj.optString("country_code", "")
                )
            }
            conn.disconnect()
        } catch (_: Exception) {}
        return mapOf("ip" to "Unavailable", "country" to "", "city" to "", "countryCode" to "")
    }

    private fun queryGeoForIp(ip: String): Map<String, Any> {
        try {
            val url = URL("https://ipwho.is/$ip?fields=country,city,country_code")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 2500
                readTimeout = 2500
                setRequestProperty("User-Agent", "ToolerBrowser/2.0")
            }
            if (conn.responseCode == 200) {
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                conn.disconnect()
                val obj = JSONObject(body)
                return mapOf(
                    "country" to obj.optString("country", "Global Relay"),
                    "city" to obj.optString("city", ""),
                    "countryCode" to obj.optString("country_code", "GL")
                )
            }
            conn.disconnect()
        } catch (_: Exception) {}
        return mapOf("country" to "Global Relay", "city" to "", "countryCode" to "GL")
    }
}
