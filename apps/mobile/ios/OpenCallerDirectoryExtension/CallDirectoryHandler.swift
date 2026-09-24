import CallKit
import Foundation
import SQLite3

class CallDirectoryHandler: CXCallDirectoryProvider {

    private let appGroupID = "group.cc.blackmatter.opencaller"
    private let dbFileName = "opencaller_store.sqlite"
    private let spamThreshold: Double = 0.80

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            NSLog("OpenCaller: App Group container URL unavailable")
            context.cancelRequest(with: NSError(domain: "OpenCallerError", code: 1, userInfo: nil))
            return
        }

        let dbPath = containerURL.appendingPathComponent(dbFileName).path
        NSLog("OpenCaller: Loading caller directory from \(dbPath)")

        guard FileManager.default.fileExists(atPath: dbPath) else {
            NSLog("OpenCaller: Shared database file does not exist yet. Sync required.")
            context.completeRequest()
            return
        }

        var db: OpaquePointer?
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            NSLog("OpenCaller: Unable to open shared SQLite database")
            context.cancelRequest(with: NSError(domain: "OpenCallerError", code: 2, userInfo: nil))
            return
        }
        defer { sqlite3_close(db) }

        // CRITICAL APPLE REQUIREMENT: Numbers MUST be ordered strictly ascending by e164_number
        let query = "SELECT e164_number, caller_name, spam_score, is_blocked FROM local_numbers ORDER BY e164_number ASC"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            NSLog("OpenCaller: Failed to prepare SQL query for call directory")
            context.cancelRequest(with: NSError(domain: "OpenCallerError", code: 3, userInfo: nil))
            return
        }
        defer { sqlite3_finalize(stmt) }

        var lastProcessedNumber: CXCallDirectoryPhoneNumber = 0
        var totalLoaded = 0

        while sqlite3_step(stmt) == SQLITE_ROW {
            let number = sqlite3_column_int64(stmt, 0)

            // STRICT ASCENDING VALIDATION:
            // Any number that is <= lastProcessedNumber violates Apple CallKit and causes silent failure.
            guard number > lastProcessedNumber else {
                NSLog("OpenCaller: Skipped out-of-order or duplicate number: \(number) <= \(lastProcessedNumber)")
                continue
            }
            lastProcessedNumber = number

            let spamScore = sqlite3_column_double(stmt, 2)
            let isBlocked = sqlite3_column_int(stmt, 3) == 1

            if isBlocked || spamScore >= spamThreshold {
                // Add to iOS native call blocking blacklist
                context.addBlockingEntry(withNextSequentialPhoneNumber: number)
            } else if let cString = sqlite3_column_text(stmt, 1) {
                // Add to iOS native caller ID identification whitelist
                let name = String(cString: cString)
                if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    context.addIdentificationEntry(withNextSequentialPhoneNumber: number, label: name)
                }
            }

            totalLoaded += 1
        }

        NSLog("OpenCaller: Loaded \(totalLoaded) caller ID and spam entries into iOS CallKit.")
        context.completeRequest()
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        NSLog("OpenCaller CallDirectoryHandler request failed: \(error.localizedDescription)")
    }
}
