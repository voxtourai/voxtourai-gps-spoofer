package ai.voxtour.voxtourai_gps_spoofer

import android.location.Location
import android.location.LocationManager
import android.location.LocationProvider
import android.location.Criteria
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.content.Intent
import android.app.AppOpsManager
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.location.FusedLocationProviderClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "voxtourai_gps_spoofer/mock_location"
    private val testProvidersReady = mutableSetOf<String>()
    private var fusedClient: FusedLocationProviderClient? = null
    private var fusedMockEnabled = false
    private var lastMockDebug: Map<String, Any?> = emptyMap()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fusedClient = LocationServices.getFusedLocationProviderClient(this)
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
                    try {
                        val status = setMockLocation(latitude, longitude, accuracy, speedMps)
                        result.success(status)
                    } catch (error: Exception) {
                        result.error("MOCK_LOCATION_ERROR", error.message, null)
                    }
                }
                "clearMockLocation" -> {
                    try {
                        val status = clearMockLocation()
                        result.success(status)
                    } catch (error: Exception) {
                        result.error("MOCK_CLEAR_ERROR", error.message, null)
                    }
                }
                "getLastKnownLocation" -> {
                    try {
                        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
                        val location = getBestLastKnownLocation(locationManager)
                        if (location == null) {
                            result.success(null)
                        } else {
                            result.success(mapOf(
                                "latitude" to location.latitude,
                                "longitude" to location.longitude,
                                "accuracy" to location.accuracy
                            ))
                        }
                    } catch (error: Exception) {
                        result.error("LOCATION_ERROR", error.message, null)
                    }
                }
                "getCurrentLocation" -> {
                    try {
                        val client = fusedClient
                        if (client == null) {
                            result.error("LOCATION_ERROR", "Fused client not available", null)
                            return@setMethodCallHandler
                        }
                        client.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null)
                            .addOnSuccessListener { location ->
                                val resolved = location ?: run {
                                    val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
                                    getBestLastKnownLocation(locationManager)
                                }
                                if (resolved == null) {
                                    result.success(null)
                                } else {
                                    result.success(mapOf<String, Any>(
                                        "latitude" to resolved.latitude,
                                        "longitude" to resolved.longitude,
                                        "accuracy" to resolved.accuracy
                                    ))
                                }
                            }
                            .addOnFailureListener { error ->
                                result.error("LOCATION_ERROR", error.message, null)
                            }
                    } catch (error: Exception) {
                        result.error("LOCATION_ERROR", error.message, null)
                    }
                }
                "getMockDebug" -> {
                    result.success(lastMockDebug)
                }
                "isDeveloperModeEnabled" -> {
                    val enabled = try {
                        Settings.Global.getInt(
                            contentResolver,
                            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                            0
                        ) == 1
                    } catch (_: Exception) {
                        false
                    }
                    result.success(enabled)
                }
                "isMockLocationApp" -> {
                    val isSelected = isMockLocationApp()
                    result.success(isSelected)
                }
                "getMockLocationApp" -> {
                    val selected = try {
                        Settings.Secure.getString(contentResolver, "mock_location_app")
                    } catch (_: Exception) {
                        null
                    }
                    result.success(selected)
                }
                "openDeveloperSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("SETTINGS_ERROR", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isMockLocationApp(): Boolean {
        return try {
            val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_MOCK_LOCATION,
                    android.os.Process.myUid(),
                    applicationContext.packageName
                )
            } else {
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_MOCK_LOCATION,
                    android.os.Process.myUid(),
                    applicationContext.packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun setMockLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        speedMps: Double
    ): Map<String, Any?> {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER)

        var gpsApplied = false
        var fusedApplied = false
        var gpsError: String? = null
        var fusedError: String? = null
        var addProviderError: String? = null
        var enableProviderError: String? = null
        var statusProviderError: String? = null
        var removeProviderError: String? = null
        var addProviderResult: String? = null
        var enableProviderResult: String? = null
        var statusProviderResult: String? = null
        var removeProviderResult: String? = null

        val baseLocation = Location(LocationManager.GPS_PROVIDER).apply {
            this.latitude = latitude
            this.longitude = longitude
            this.accuracy = accuracy.toFloat()
            this.speed = speedMps.toFloat()
            time = System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
            }
        }

        try {
            fusedClient?.let { client ->
                if (!fusedMockEnabled) {
                    client.setMockMode(true)
                    fusedMockEnabled = true
                }
                client.setMockLocation(baseLocation)
                fusedApplied = true
            }
        } catch (error: Exception) {
            fusedError = error.message
        }

        for (provider in providers) {
            var ensured = testProvidersReady.contains(provider)
            if (!ensured) {
                val ensureResult = ensureTestProvider(locationManager, provider)
                ensured = ensureResult.success
                addProviderError = ensureResult.addError
                enableProviderError = ensureResult.enableError
                statusProviderError = ensureResult.statusError
                removeProviderError = ensureResult.removeError
                addProviderResult = ensureResult.addResult
                enableProviderResult = ensureResult.enableResult
                statusProviderResult = ensureResult.statusResult
                removeProviderResult = ensureResult.removeResult
                if (ensured) {
                    testProvidersReady.add(provider)
                }
            }

            val location = Location(provider).apply {
                this.latitude = latitude
                this.longitude = longitude
                this.accuracy = accuracy.toFloat()
                this.speed = speedMps.toFloat()
                time = System.currentTimeMillis()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                    elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
                }
            }

            try {
                locationManager.setTestProviderLocation(provider, location)
                try {
                    locationManager.setTestProviderStatus(
                        provider,
                        LocationProvider.AVAILABLE,
                        null,
                        System.currentTimeMillis()
                    )
                } catch (_: Exception) {
                    // Ignore status failures.
                }
                gpsApplied = true
            } catch (error: Exception) {
                val message = error.message ?: "Unknown GPS mock error"
                if (message.contains("not a test provider", ignoreCase = true)) {
                    // Retry after forcing test provider setup.
                    val ensureResult = ensureTestProvider(locationManager, provider)
                    addProviderError = ensureResult.addError
                    enableProviderError = ensureResult.enableError
                    statusProviderError = ensureResult.statusError
                    removeProviderError = ensureResult.removeError
                    addProviderResult = ensureResult.addResult
                    enableProviderResult = ensureResult.enableResult
                    statusProviderResult = ensureResult.statusResult
                    removeProviderResult = ensureResult.removeResult
                    if (ensureResult.success) {
                        try {
                            locationManager.setTestProviderLocation(provider, location)
                            gpsApplied = true
                        } catch (retryError: Exception) {
                            gpsError = retryError.message
                        }
                    } else {
                        gpsError = message
                    }
                } else {
                    gpsError = message
                }
            }
        }

        val status = mapOf(
            "gpsApplied" to gpsApplied,
            "fusedApplied" to fusedApplied,
            "gpsError" to gpsError,
            "fusedError" to fusedError,
            "addProviderError" to addProviderError,
            "enableProviderError" to enableProviderError,
            "statusProviderError" to statusProviderError,
            "removeProviderError" to removeProviderError,
            "addProviderResult" to addProviderResult,
            "enableProviderResult" to enableProviderResult,
            "statusProviderResult" to statusProviderResult,
            "removeProviderResult" to removeProviderResult,
            "mockAppSelected" to isMockLocationApp()
        )
        lastMockDebug = status
        return status
    }
    private fun clearMockLocation(): Map<String, Any?> {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER)

        var gpsCleared = false
        var fusedCleared = false
        var gpsError: String? = null
        var fusedError: String? = null

        for (provider in providers) {
            try {
                locationManager.removeTestProvider(provider)
                gpsCleared = true
            } catch (error: Exception) {
                gpsError = error.message
            }
        }

        try {
            fusedClient?.let { client ->
                if (fusedMockEnabled) {
                    client.setMockMode(false)
                    fusedMockEnabled = false
                    fusedCleared = true
                }
            }
        } catch (error: Exception) {
            fusedError = error.message
        }

        testProvidersReady.clear()

        val status = mapOf(
            "gpsCleared" to gpsCleared,
            "fusedCleared" to fusedCleared,
            "gpsError" to gpsError,
            "fusedError" to fusedError,
            "mockAppSelected" to isMockLocationApp()
        )
        lastMockDebug = status
        return status
    }

    private fun getBestLastKnownLocation(locationManager: LocationManager): Location? {
        var best: Location? = null
        val providers = locationManager.getProviders(true)
        for (provider in providers) {
            val location = try {
                locationManager.getLastKnownLocation(provider)
            } catch (_: SecurityException) {
                null
            }
            if (location != null) {
                if (best == null || location.time > best!!.time) {
                    best = location
                }
            }
        }
        return best
    }




    private data class ProviderSetupResult(
        val success: Boolean,
        val removeError: String?,
        val addError: String?,
        val enableError: String?,
        val statusError: String?,
        val removeResult: String?,
        val addResult: String?,
        val enableResult: String?,
        val statusResult: String?
    )

    private fun ensureTestProvider(locationManager: LocationManager, provider: String): ProviderSetupResult {
        var removeError: String? = null
        var addError: String? = null
        var enableError: String? = null
        var statusError: String? = null
        var removeResult: String? = null
        var addResult: String? = null
        var enableResult: String? = null
        var statusResult: String? = null

        try {
            locationManager.removeTestProvider(provider)
            removeResult = "removed"
        } catch (error: Exception) {
            removeError = error.javaClass.simpleName + ": " + (error.message ?: "unknown")
        }

        var success = false
        try {
            locationManager.addTestProvider(
                provider,
                false,
                false,
                false,
                false,
                true,
                true,
                true,
                Criteria.POWER_LOW,
                Criteria.ACCURACY_FINE
            )
            addResult = "added"
            success = true
        } catch (error: Exception) {
            addError = error.javaClass.simpleName + ": " + (error.message ?: "unknown")
        }

        try {
            locationManager.setTestProviderEnabled(provider, true)
            enableResult = "enabled"
        } catch (error: Exception) {
            enableError = error.javaClass.simpleName + ": " + (error.message ?: "unknown")
        }

        try {
            locationManager.setTestProviderStatus(
                provider,
                LocationProvider.AVAILABLE,
                null,
                System.currentTimeMillis()
            )
            statusResult = "available"
        } catch (error: Exception) {
            statusError = error.javaClass.simpleName + ": " + (error.message ?: "unknown")
        }

        return ProviderSetupResult(
            success = success,
            removeError = removeError,
            addError = addError,
            enableError = enableError,
            statusError = statusError,
            removeResult = removeResult,
            addResult = addResult,
            enableResult = enableResult,
            statusResult = statusResult
        )
    }
}
