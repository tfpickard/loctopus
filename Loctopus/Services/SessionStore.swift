import Foundation

actor SessionStore {
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var sessions: [Session] = []

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        baseURL = docs.appendingPathComponent("Sessions", isDirectory: true)
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        Task { await loadSessions() }
    }

    func allSessions() async -> [Session] {
        sessions.sorted { $0.createdAt > $1.createdAt }
    }

    func createSession(name: String, sensors: [SensorType]) async throws -> Session {
        let session = Session(name: name, sensorsEnabled: sensors, duration: 0)
        sessions.append(session)
        try persist(session: session)
        return session
    }

    func updateSession(_ session: Session) async throws {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        try persist(session: session)
    }

    func deleteSession(_ session: Session) async throws {
        sessions.removeAll { $0.id == session.id }
        let folder = baseURL.appendingPathComponent(session.id.uuidString, isDirectory: true)
        if fileManager.fileExists(atPath: folder.path) {
            try fileManager.removeItem(at: folder)
        }
        try saveIndex()
    }

    func append<T: Encodable>(_ sample: T, for session: Session, sensor: SensorType) async throws {
        let folder = try sessionFolder(for: session)
        let fileURL = folder.appendingPathComponent("\(sensor.rawValue).jsonl")
        let handle: FileHandle
        if fileManager.fileExists(atPath: fileURL.path) {
            handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
        } else {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
            handle = try FileHandle(forWritingTo: fileURL)
        }
        let data = try encoder.encode(sample)
        handle.write(data)
        handle.write("\n".data(using: .utf8)!)
        try handle.close()
    }

    func loadSamples<T: Decodable>(for session: Session, sensor: SensorType, as type: T.Type) throws -> [T] {
        let folder = baseURL.appendingPathComponent(session.id.uuidString, isDirectory: true)
        let fileURL = folder.appendingPathComponent("\(sensor.rawValue).jsonl")
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let content = try String(contentsOf: fileURL)
        let lines = content.split(separator: "\n")
        return try lines.map { line in
            let data = Data(line.utf8)
            return try decoder.decode(T.self, from: data)
        }
    }

    private func sessionFolder(for session: Session) throws -> URL {
        let folder = baseURL.appendingPathComponent(session.id.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func persist(session: Session) throws {
        let folder = try sessionFolder(for: session)
        let url = folder.appendingPathComponent("metadata.json")
        let data = try encoder.encode(session)
        try data.write(to: url)
        try saveIndex()
    }

    private func loadSessions() async {
        let contents = (try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)) ?? []
        var loaded: [Session] = []
        for url in contents where url.hasDirectoryPath {
            let meta = url.appendingPathComponent("metadata.json")
            if let data = try? Data(contentsOf: meta), let session = try? decoder.decode(Session.self, from: data) {
                loaded.append(session)
            }
        }
        sessions = loaded
        try? saveIndex()
    }

    private func saveIndex() throws {
        let indexURL = baseURL.appendingPathComponent("sessionsIndex.json")
        let data = try encoder.encode(sessions)
        try data.write(to: indexURL)
    }
}
