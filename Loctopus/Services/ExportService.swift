import Foundation
import CoreLocation

struct ExportService {
    func exportJSON(session: Session, store: SessionStore) async throws -> URL {
        let data = try await buildExport(session: session, store: store)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.id)-export.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(data).write(to: url)
        return url
    }

    func exportCSV(session: Session, store: SessionStore) async throws -> URL {
        let export = try await buildExport(session: session, store: store)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.id)-export.csv")
        var rows: [String] = ["type,timestamp,x,y,z,latitude,longitude,altitude,speed,course,pressure,relativeAltitude"]
        let formatter = ISO8601DateFormatter()
        for sample in export.accelerometer {
            rows.append("accelerometer,\(formatter.string(from: sample.timestamp)),\(sample.x),\(sample.y),\(sample.z),,,,,,")
        }
        for sample in export.gyroscope {
            rows.append("gyroscope,\(formatter.string(from: sample.timestamp)),\(sample.x),\(sample.y),\(sample.z),,,,,,")
        }
        for sample in export.magnetometer {
            rows.append("magnetometer,\(formatter.string(from: sample.timestamp)),\(sample.x),\(sample.y),\(sample.z),,,,,,")
        }
        for sample in export.barometer {
            rows.append("barometer,\(formatter.string(from: sample.timestamp)),,,,,,,\(sample.pressure),\(sample.relativeAltitude ?? 0)")
        }
        for sample in export.gps {
            rows.append("gps,\(formatter.string(from: sample.timestamp)),,,,\(sample.latitude),\(sample.longitude),\(sample.altitude),\(sample.speed),\(sample.course),,")
        }
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportGPX(session: Session, store: SessionStore) async throws -> URL {
        let gps = try await store.loadSamples(for: session, sensor: .gps, as: GPSSample.self)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.id).gpx")
        let formatter = ISO8601DateFormatter()
        var gpx = ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "<gpx version=\"1.1\" creator=\"Loctopus\" xmlns=\"http://www.topografix.com/GPX/1/1\">", "<trk><name>\(session.name)</name><trkseg>"]
        for sample in gps {
            gpx.append("<trkpt lat=\"\(sample.latitude)\" lon=\"\(sample.longitude)\"><ele>\(sample.altitude)</ele><time>\(formatter.string(from: sample.timestamp))</time></trkpt>")
        }
        gpx.append("</trkseg></trk></gpx>")
        try gpx.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportZIP(session: Session, store: SessionStore) async throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(session.id.uuidString)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let json = try await exportJSON(session: session, store: store)
        let csv = try await exportCSV(session: session, store: store)
        let gpx = try await exportGPX(session: session, store: store)
        try FileManager.default.copyItem(at: json, to: folder.appendingPathComponent(json.lastPathComponent))
        try FileManager.default.copyItem(at: csv, to: folder.appendingPathComponent(csv.lastPathComponent))
        try FileManager.default.copyItem(at: gpx, to: folder.appendingPathComponent(gpx.lastPathComponent))
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.id).zip")
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        coordinator.coordinate(readingItemAt: folder, options: .forUploading, error: &coordError) { zip in
            do { try FileManager.default.copyItem(at: zip, to: zipURL) } catch { coordError = error as NSError }
        }
        if let coordError { throw coordError }
        return zipURL
    }

    private func buildExport(session: Session, store: SessionStore) async throws -> SessionExport {
        let gps = try await store.loadSamples(for: session, sensor: .gps, as: GPSSample.self)
        let accel = try await store.loadSamples(for: session, sensor: .accelerometer, as: MotionSample.self)
        let gyro = try await store.loadSamples(for: session, sensor: .gyroscope, as: MotionSample.self)
        let mag = try await store.loadSamples(for: session, sensor: .magnetometer, as: MotionSample.self)
        let baro = try await store.loadSamples(for: session, sensor: .barometer, as: BarometerSample.self)
        return SessionExport(session: session, gps: gps, accelerometer: accel, gyroscope: gyro, magnetometer: mag, barometer: baro)
    }
}
