package ai.voxtour.voxtourai_gps_spoofer

import android.location.Location
import android.location.LocationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "voxtourai_gps_spoofer/mock_location"
    private var testProviderReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setMockLocation" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    val accuracy = call.argument<Double>("accuracy") ?: 3.0
                    val speedMps = call.argument<Double>("speedMps") ?: 0.0
                    if (latitude == null || longitude == null) {
                        result.error("ARGUMENT_ERROR", "Missing latitude/longitude", null)
                        return@setMethodCallHandler
                    }
                    setMockLocation(latitude, longitude, accuracy, speedMps)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setMockLocation(latitude: Double, longitude: Double, accuracy: Double, speedMps: Double) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        val provider = LocationManager.GPS_PROVIDER
        if (!testProviderReady) {
            locationManager.addTestProvider(
                provider,
                false,
                false,
                false,
                false,
                true,
                true,
                true,
                0,
                5
            )
            locationManager.setTestProviderEnabled(provider, true)
            testProviderReady = true
        }

        val location = Location(provider).apply {
            this.latitude = latitude
            this.longitude = longitude
            this.accuracy = accuracy.toFloat()
            this.speed = speedMps.toFloat()
            time = System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                elapsedRealtimeNanos = System.nanoTime()
            }
        }
        locationManager.setTestProviderLocation(provider, location)
    }
}
