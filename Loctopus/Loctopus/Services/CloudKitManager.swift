import Foundation
import CloudKit

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    @Published var isSyncEnabled = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let storageManager = StorageManager.shared

    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase

        loadSyncSettings()
    }

    // MARK: - Settings
    func enableSync() {
        isSyncEnabled = true
        saveSyncSettings()
        Task {
            await syncAllSessions()
        }
    }

    func disableSync() {
        isSyncEnabled = false
        saveSyncSettings()
    }

    private func saveSyncSettings() {
        UserDefaults.standard.set(isSyncEnabled, forKey: "iCloudSyncEnabled")
    }

    private func loadSyncSettings() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }

    // MARK: - Account Status
    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            print("Failed to check iCloud account status: \(error)")
            return false
        }
    }

    // MARK: - Upload Sessions
    func uploadSession(_ session: Session) async {
        guard isSyncEnabled else { return }

        do {
            let record = session.toCKRecord()

            // Upload metadata
            let savedRecord = try await privateDatabase.save(record)

            // Upload sensor data as assets
            try await uploadSensorData(for: session, recordID: savedRecord.recordID)

            // Update local session with iCloud record ID
            var updatedSession = session
            updatedSession.iCloudRecordID = savedRecord.recordID.recordName
            storageManager.updateSession(updatedSession)

        } catch {
            print("Failed to upload session: \(error)")
            syncError = error.localizedDescription
        }
    }

    private func uploadSensorData(for session: Session, recordID: CKRecord.ID) async throws {
        let sessionDir = storageManager.getSessionDirectoryURL(for: session.id)

        for sensor in session.sensorsEnabled {
            let sensorFile = sessionDir.appendingPathComponent("\(sensor.rawValue.lowercased()).jsonl")

            guard FileManager.default.fileExists(atPath: sensorFile.path) else { continue }

            let asset = CKAsset(fileURL: sensorFile)
            let dataRecord = CKRecord(recordType: "SensorData", recordID: CKRecord.ID(zoneID: recordID.zoneID))
            dataRecord["sessionID"] = session.id.uuidString as CKRecordValue
            dataRecord["sensorType"] = sensor.rawValue as CKRecordValue
            dataRecord["data"] = asset

            _ = try await privateDatabase.save(dataRecord)
        }
    }

    // MARK: - Download Sessions
    func downloadAllSessions() async {
        guard isSyncEnabled else { return }

        isSyncing = true
        syncError = nil

        do {
            let query = CKQuery(recordType: Session.recordType, predicate: NSPredicate(value: true))
            let results = try await privateDatabase.records(matching: query)

            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let session = Session(from: record) {
                        // Check if we already have this session
                        if !storageManager.sessions.contains(where: { $0.id == session.id }) {
                            // Download sensor data
                            await downloadSensorData(for: session)

                            // Add to local storage
                            storageManager.sessions.insert(session, at: 0)
                        }
                    }
                case .failure(let error):
                    print("Failed to fetch session record: \(error)")
                }
            }

            lastSyncDate = Date()
            isSyncing = false

        } catch {
            print("Failed to download sessions: \(error)")
            syncError = error.localizedDescription
            isSyncing = false
        }
    }

    private func downloadSensorData(for session: Session) async {
        let sessionDir = storageManager.getSessionDirectoryURL(for: session.id)

        // Create session directory
        try? FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Query for sensor data records
        let predicate = NSPredicate(format: "sessionID == %@", session.id.uuidString)
        let query = CKQuery(recordType: "SensorData", predicate: predicate)

        do {
            let results = try await privateDatabase.records(matching: query)

            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let asset = record["data"] as? CKAsset,
                       let fileURL = asset.fileURL,
                       let sensorTypeString = record["sensorType"] as? String,
                       let sensorType = SensorType(rawValue: sensorTypeString) {

                        let destinationURL = sessionDir.appendingPathComponent("\(sensorType.rawValue.lowercased()).jsonl")
                        try? FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    }
                case .failure(let error):
                    print("Failed to fetch sensor data: \(error)")
                }
            }
        } catch {
            print("Failed to download sensor data: \(error)")
        }
    }

    // MARK: - Sync All
    func syncAllSessions() async {
        guard isSyncEnabled else { return }

        isSyncing = true

        // Upload all local sessions that aren't synced
        for session in storageManager.sessions where session.iCloudRecordID == nil {
            await uploadSession(session)
        }

        // Download new sessions from iCloud
        await downloadAllSessions()

        lastSyncDate = Date()
        isSyncing = false
    }

    // MARK: - Delete
    func deleteSession(_ session: Session) async {
        guard let recordIDString = session.iCloudRecordID else { return }

        do {
            let recordID = CKRecord.ID(recordName: recordIDString)
            try await privateDatabase.deleteRecord(withID: recordID)

            // Also delete sensor data records
            let predicate = NSPredicate(format: "sessionID == %@", session.id.uuidString)
            let query = CKQuery(recordType: "SensorData", predicate: predicate)

            let results = try await privateDatabase.records(matching: query)

            for (recordID, _) in results.matchResults {
                try? await privateDatabase.deleteRecord(withID: recordID)
            }

        } catch {
            print("Failed to delete session from iCloud: \(error)")
        }
    }
}
