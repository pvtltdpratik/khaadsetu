package com.example.khaadsetu_version1

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Also hosts the channel the app's self-update uses (lib/core/update): which version is installed, whether Android lets
/// this app install packages, and handing a downloaded APK to Android's installer.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shetsamrudhi/update").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "version" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                        result.success(mapOf("code" to code, "name" to (info.versionName ?: "")))
                    }
                    "canInstall" -> result.success(Build.VERSION.SDK_INT < 26 || packageManager.canRequestPackageInstalls())
                    "openInstallSettings" -> {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
                        startActivity(intent)
                        result.success(null)
                    }
                    "install" -> {
                        val path = call.argument<String>("path") ?: throw IllegalArgumentException("path")
                        val uri = FileProvider.getUriForFile(this, "$packageName.updates", File(path))
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("update_failed", e.message, null)
            }
        }
    }
}
