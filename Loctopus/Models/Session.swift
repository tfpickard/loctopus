import Foundation

struct Session: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var endedAt: Date?
    var tags: [String]
    var notes: String?
    var sensorsEnabled: [SensorType]
    var duration: TimeInterval
    var sampleCounts: [SensorType: Int]

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, endedAt: Date? = nil, tags: [String] = [], notes: String? = nil, sensorsEnabled: [SensorType], duration: TimeInterval = 0, sampleCounts: [SensorType: Int] = [:]) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.tags = tags
        self.notes = notes
        self.sensorsEnabled = sensorsEnabled
        self.duration = duration
        self.sampleCounts = sampleCounts
    }

    var isActive: Bool { endedAt == nil }
}
