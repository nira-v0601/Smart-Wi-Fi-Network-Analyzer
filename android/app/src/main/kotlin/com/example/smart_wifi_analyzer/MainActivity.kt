package com.example.smart_wifi_analyzer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.wifi.WifiManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smart_wifi_analyzer/wifi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRssi") {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val info = wifiManager.connectionInfo
                if (info != null && info.networkId != -1) {
                    result.success(info.rssi)
                } else {
                    result.success(null)
                }
            } else if (call.method == "getSecurityType") {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val info = wifiManager.connectionInfo
                if (info != null && info.networkId != -1) {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        result.success(info.currentSecurityType)
                    } else {
                        result.success(-1)
                    }
                } else {
                    result.success(-1)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
