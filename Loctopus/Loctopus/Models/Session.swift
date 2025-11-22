import Foundation
import CloudKit

struct Session: Identifiable, Codable {
    let id: UUID
    var name: String
    var notes: String
    var tags: [String]
    let createdAt: Date
    var endedAt: Date?
    var sensorsEnabled: [SensorType]
    var statistics: SessionStatistics
    var iCloudRecordID: String?

    var duration: TimeInterval {
        guard let endedAt = endedAt else {
            return Date().timeIntervalSince(createdAt)
        }
        return endedAt.timeIntervalSince(createdAt)
    }

    var isRecording: Bool {
        endedAt == nil
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    init(
        id: UUID = UUID(),
        name: String? = nil,
        notes: String = "",
        tags: [String] = [],
        createdAt: Date = Date(),
        endedAt: Date? = nil,
        sensorsEnabled: [SensorType] = [],
        statistics: SessionStatistics = SessionStatistics(),
        iCloudRecordID: String? = nil
    ) {
        self.id = id
        self.name = name ?? "Session at \(Session.defaultFormatter.string(from: createdAt))"
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.sensorsEnabled = sensorsEnabled
        self.statistics = statistics
        self.iCloudRecordID = iCloudRecordID
    }

    private static let defaultFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - CloudKit Support
extension Session {
    static let recordType = "Session"

    func toCKRecord() -> CKRecord {
        let record: CKRecord
        if let recordIDString = iCloudRecordID,
           let recordID = CKRecord.ID(recordName: recordIDString, zoneID: .default) as? CKRecord.ID {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: Self.recordType)
        }

        record["id"] = id.uuidString as CKRecordValue
        record["name"] = name as CKRecordValue
        record["notes"] = notes as CKRecordValue
        record["tags"] = tags as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        record["sensorsEnabled"] = sensorsEnabled.map { $0.rawValue } as CKRecordValue

        if let statsData = try? JSONEncoder().encode(statistics) {
            record["statistics"] = String(data: statsData, encoding: .utf8) as? CKRecordValue
        }

        return record
    }

    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        self.id = id
        self.name = name
        self.notes = record["notes"] as? String ?? ""
        self.tags = record["tags"] as? [String] ?? []
        self.createdAt = createdAt
        self.endedAt = record["endedAt"] as? Date

        if let sensorStrings = record["sensorsEnabled"] as? [String] {
            self.sensorsEnabled = sensorStrings.compactMap { SensorType(rawValue: $0) }
        } else {
            self.sensorsEnabled = []
        }

        if let statsString = record["statistics"] as? String,
           let statsData = statsString.data(using: .utf8),
           let stats = try? JSONDecoder().decode(SessionStatistics.self, from: statsData) {
            self.statistics = stats
        } else {
            self.statistics = SessionStatistics()
        }

        self.iCloudRecordID = record.recordID.recordName
    }
}
