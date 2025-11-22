import Foundation

@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()

    @Published var sessions: [Session] = []

    private let fileManager = FileManager.default
    private let sessionsDirectoryURL: URL
    private let metadataFileURL: URL

    private init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        sessionsDirectoryURL = documentsURL.appendingPathComponent("Sessions")
        metadataFileURL = documentsURL.appendingPathComponent("sessions_metadata.json")

        createDirectoriesIfNeeded()
        loadSessions()
    }

    // MARK: - Setup
    private func createDirectoriesIfNeeded() {
        if !fileManager.fileExists(atPath: sessionsDirectoryURL.path) {
            try? fileManager.createDirectory(at: sessionsDirectoryURL, withIntermediateDirectories: true)
        }
    }

    func getSessionDirectoryURL(for sessionID: UUID) -> URL {
        sessionsDirectoryURL.appendingPathComponent(sessionID.uuidString)
    }

    // MARK: - Session Management
    func createSession(name: String? = nil, sensors: [SensorType]) -> Session {
        let session = Session(
            name: name,
            sensorsEnabled: sensors
        )

        let sessionDir = getSessionDirectoryURL(for: session.id)
        try? fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        sessions.insert(session, at: 0)
        saveSessions()
        return session
    }

    func updateSession(_ session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }

    func deleteSession(_ session: Session) {
        let sessionDir = getSessionDirectoryURL(for: session.id)
        try? fileManager.removeItem(at: sessionDir)

        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func endSession(_ session: Session) {
        var updatedSession = session
        updatedSession.endedAt = Date()
        updateSession(updatedSession)
    }

    // MARK: - Metadata Persistence
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: metadataFileURL)
        } catch {
            print("Failed to save sessions metadata: \(error)")
        }
    }

    private func loadSessions() {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            sessions = []
            return
        }

        do {
            let data = try Data(contentsOf: metadataFileURL)
            sessions = try JSONDecoder().decode([Session].self, from: data)
        } catch {
            print("Failed to load sessions metadata: \(error)")
            sessions = []
        }
    }

    // MARK: - Sensor Data Storage
    func saveSensorSample<T: SensorSample>(_ sample: T, sessionID: UUID, sensorType: SensorType) {
        let sessionDir = getSessionDirectoryURL(for: sessionID)
        let sensorFile = sessionDir.appendingPathComponent("\(sensorType.rawValue.lowercased()).jsonl")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(sample)

            var jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            jsonString += "\n"

            if let data = jsonString.data(using: .utf8) {
                if fileManager.fileExists(atPath: sensorFile.path) {
                    let fileHandle = try FileHandle(forWritingTo: sensorFile)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try fileHandle.close()
                } else {
                    try data.write(to: sensorFile)
                }
            }
        } catch {
            print("Failed to save \(sensorType.rawValue) sample: \(error)")
        }
    }

    func loadSensorSamples<T: SensorSample>(
        sessionID: UUID,
        sensorType: SensorType,
        type: T.Type
    ) -> [T] {
        let sessionDir = getSessionDirectoryURL(for: sessionID)
        let sensorFile = sessionDir.appendingPathComponent("\(sensorType.rawValue.lowercased()).jsonl")

        guard fileManager.fileExists(atPath: sensorFile.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: sensorFile)
            let lines = String(data: data, encoding: .utf8)?
                .split(separator: "\n")
                .map(String.init) ?? []

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return lines.compactMap { line in
                guard let lineData = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(T.self, from: lineData)
            }
        } catch {
            print("Failed to load \(sensorType.rawValue) samples: \(error)")
            return []
        }
    }

    // MARK: - Statistics
    func updateSessionStatistics(sessionID: UUID, statistics: SessionStatistics) {
        if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
            sessions[index].statistics = statistics
            saveSessions()
        }
    }

    // MARK: - Storage Info
    func getStorageSize() -> UInt64 {
        var totalSize: UInt64 = 0

        guard let enumerator = fileManager.enumerator(at: sessionsDirectoryURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += UInt64(fileSize)
        }

        return totalSize
    }

    func getFormattedStorageSize() -> String {
        let bytes = getStorageSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
