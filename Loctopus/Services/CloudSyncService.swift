import Foundation
import CloudKit

final class CloudSyncService {
    private let container: CKContainer
    private let database: CKDatabase
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(containerIdentifier: String? = nil) {
        if let id = containerIdentifier {
            container = CKContainer(identifier: id)
        } else {
            container = CKContainer.default()
        }
        database = container.privateCloudDatabase
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func sync(session: Session, folder: URL) async throws {
        let recordID = CKRecord.ID(recordName: session.id.uuidString)
        let record = CKRecord(recordType: "Session", recordID: recordID)
        record["name"] = session.name as CKRecordValue
        record["createdAt"] = session.createdAt as NSDate
        record["endedAt"] = session.endedAt as NSDate?
        record["sensors"] = session.sensorsEnabled.map { $0.rawValue } as CKRecordValue
        record["duration"] = session.duration as CKRecordValue

        let metaURL = folder.appendingPathComponent("metadata.json")
        if FileManager.default.fileExists(atPath: metaURL.path) {
            let asset = CKAsset(fileURL: metaURL)
            record["metadata"] = asset
        }
        let zipURL = folder.appendingPathComponent("session.zip")
        try zipFolder(sourceURL: folder, destinationURL: zipURL)
        record["archive"] = CKAsset(fileURL: zipURL)
        let _ = try await database.save(record)
        try? FileManager.default.removeItem(at: zipURL)
    }

    func fetchRemoteSessions() async throws -> [Session] {
        let query = CKQuery(recordType: "Session", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        return result.matchResults.compactMap { _, value in
            guard case .success(let record) = value else { return nil }
            return decodeSession(from: record)
        }
    }

    private func decodeSession(from record: CKRecord) -> Session? {
        guard let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let sensors = record["sensors"] as? [String]
        else { return nil }
        let endedAt = record["endedAt"] as? Date
        let duration = record["duration"] as? TimeInterval ?? 0
        let sensorTypes = sensors.compactMap { SensorType(rawValue: $0) }
        return Session(id: UUID(uuidString: record.recordID.recordName) ?? UUID(), name: name, createdAt: createdAt, endedAt: endedAt, sensorsEnabled: sensorTypes, duration: duration)
    }

    private func zipFolder(sourceURL: URL, destinationURL: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &coordError) { zipURL in
            do {
                try fileManager.copyItem(at: zipURL, to: destinationURL)
            } catch {
                coordError = error as NSError
            }
        }
        if let coordError {
            throw coordError
        }
    }
}
