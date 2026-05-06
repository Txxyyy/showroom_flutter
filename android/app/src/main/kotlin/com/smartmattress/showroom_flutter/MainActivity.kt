package com.smartmattress.showroom_flutter

import android.graphics.Bitmap
import android.net.Uri
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.RequiresApi
import androidx.webkit.WebViewAssetLoader
import java.io.IOException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_mattress_asset_loader"
        ).setMethodCallHandler { call, result ->
            if (call.method != "attach") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val webViewIdentifier = call.argument<Number>("webViewIdentifier")?.toLong()
            if (webViewIdentifier == null) {
                result.error("missing_webview", "Missing webViewIdentifier.", null)
                return@setMethodCallHandler
            }

            val webView = resolveWebView(flutterEngine, webViewIdentifier)
            if (webView == null) {
                result.error("missing_webview", "Unable to resolve Android WebView.", null)
                return@setMethodCallHandler
            }

            val assetLoader = WebViewAssetLoader.Builder()
                .addPathHandler("/flutter_assets/", FlutterAssetPathHandler(this))
                .build()
            val delegate = webView.webViewClient ?: WebViewClient()
            webView.webViewClient = AssetLoaderWebViewClient(assetLoader, delegate)
            result.success(null)
        }
    }

    private fun resolveWebView(flutterEngine: FlutterEngine, identifier: Long): WebView? {
        val plugin = flutterEngine.plugins.get(WebViewFlutterPlugin::class.java)
                as? WebViewFlutterPlugin ?: return null
        return plugin.instanceManager?.getInstance<WebView>(identifier)
    }

    private class AssetLoaderWebViewClient(
        private val assetLoader: WebViewAssetLoader,
        private val delegate: WebViewClient
    ) : WebViewClient() {
        override fun shouldInterceptRequest(
            view: WebView,
            request: WebResourceRequest
        ): WebResourceResponse? {
            return assetLoader.shouldInterceptRequest(request.url)
                ?: delegate.shouldInterceptRequest(view, request)
        }

        override fun shouldInterceptRequest(
            view: WebView,
            url: String
        ): WebResourceResponse? {
            return assetLoader.shouldInterceptRequest(Uri.parse(url))
                ?: delegate.shouldInterceptRequest(view, url)
        }

        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            return delegate.shouldOverrideUrlLoading(view, request)
        }

        override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
            return delegate.shouldOverrideUrlLoading(view, url)
        }

        override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
            delegate.onPageStarted(view, url, favicon)
        }

        override fun onPageFinished(view: WebView, url: String) {
            delegate.onPageFinished(view, url)
        }

        override fun onReceivedHttpError(
            view: WebView,
            request: WebResourceRequest,
            errorResponse: WebResourceResponse
        ) {
            delegate.onReceivedHttpError(view, request, errorResponse)
        }

        @RequiresApi(23)
        override fun onReceivedError(
            view: WebView,
            request: WebResourceRequest,
            error: android.webkit.WebResourceError
        ) {
            delegate.onReceivedError(view, request, error)
        }

        @Suppress("DEPRECATION")
        override fun onReceivedError(
            view: WebView,
            errorCode: Int,
            description: String,
            failingUrl: String
        ) {
            delegate.onReceivedError(view, errorCode, description, failingUrl)
        }
    }

    private class FlutterAssetPathHandler(
        private val activity: MainActivity
    ) : WebViewAssetLoader.PathHandler {
        override fun handle(path: String): WebResourceResponse {
            val normalizedPath = path.trimStart('/')
            return try {
                WebResourceResponse(
                    mimeType(normalizedPath),
                    "UTF-8",
                    activity.assets.open("flutter_assets/$normalizedPath")
                )
            } catch (_: IOException) {
                WebResourceResponse(null, null, null)
            }
        }

        private fun mimeType(path: String): String {
            return when {
                path.endsWith(".html") -> "text/html"
                path.endsWith(".js") -> "text/javascript"
                path.endsWith(".json") -> "application/json"
                path.endsWith(".css") -> "text/css"
                path.endsWith(".glb") -> "model/gltf-binary"
                path.endsWith(".gltf") -> "model/gltf+json"
                path.endsWith(".wasm") -> "application/wasm"
                path.endsWith(".png") -> "image/png"
                path.endsWith(".jpg") || path.endsWith(".jpeg") -> "image/jpeg"
                path.endsWith(".webp") -> "image/webp"
                path.endsWith(".svg") -> "image/svg+xml"
                else -> "application/octet-stream"
            }
        }
    }
}
