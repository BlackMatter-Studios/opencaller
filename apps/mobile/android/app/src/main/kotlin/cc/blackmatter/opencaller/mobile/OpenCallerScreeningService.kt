package cc.blackmatter.opencaller.mobile

import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.annotation.RequiresApi
import java.io.File

@RequiresApi(Build.VERSION_CODES.Q)
class OpenCallerScreeningService : CallScreeningService() {

    companion object {
        private const val TAG = "OpenCallerScreening"
        private const val SPAM_THRESHOLD = 0.80
    }

    override fun onScreenCall(details: Call.Details) {
        val handle = details.handle ?: return
        val rawNumber = handle.schemeSpecificPart ?: return
        val digitsOnly = rawNumber.replace(Regex("[^0-9]"), "")
        val e164Number = digitsOnly.toLongOrNull()

        if (e164Number == null) {
            respondAllowed(details)
            return
        }

        Log.d(TAG, "Screening incoming call: +$e164Number")

        val dbFile = findDatabaseFile()
        if (dbFile == null || !dbFile.exists()) {
            Log.w(TAG, "OpenCaller SQLite database not found, allowing call")
            respondAllowed(details)
            return
        }

        var isSpam = false
        var spamScore = 0.0
        var callerName: String? = null

        try {
            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
            db.use { database ->
                // Query local numbers table
                val cursor = database.rawQuery(
                    "SELECT caller_name, spam_score, is_blocked FROM local_numbers WHERE e164_number = ? LIMIT 1",
                    arrayOf(e164Number.toString())
                )
                cursor.use {
                    if (it.moveToFirst()) {
                        callerName = if (!it.isNull(0)) it.getString(0) else null
                        spamScore = if (!it.isNull(1)) it.getDouble(1) else 0.0
                        val isBlocked = if (!it.isNull(2)) it.getInt(2) == 1 else false
                        isSpam = isBlocked || spamScore >= SPAM_THRESHOLD
                    }
                }

                // Record call to call_logs for Flutter UI
                val values = ContentValues().apply {
                    put("e164_number", e164Number)
                    put("caller_name", callerName)
                    put("call_type", if (isSpam) "blocked" else "incoming")
                    put("spam_score", spamScore)
                    put("timestamp", System.currentTimeMillis() / 1000)
                }
                database.insert("call_logs", null, values)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying screening database: ${e.message}", e)
        }

        if (isSpam) {
            Log.i(TAG, "Auto-blocking scam/spam call: +$e164Number (Score: $spamScore, Name: $callerName)")
            val response = CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
            respondToCall(details, response)
        } else {
            Log.i(TAG, "Allowed call: +$e164Number (Name: $callerName)")
            respondAllowed(details)
        }
    }

    private fun respondAllowed(details: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(details, response)
    }

    private fun findDatabaseFile(): File? {
        // Search standard Flutter path_provider locations
        val candidate1 = File(applicationContext.filesDir, "app_flutter/opencaller_store.sqlite")
        if (candidate1.exists()) return candidate1

        val candidate2 = File(applicationContext.filesDir, "opencaller_store.sqlite")
        if (candidate2.exists()) return candidate2

        val candidate3 = File(applicationContext.dataDir, "app_flutter/opencaller_store.sqlite")
        if (candidate3.exists()) return candidate3

        return candidate1
    }
}
