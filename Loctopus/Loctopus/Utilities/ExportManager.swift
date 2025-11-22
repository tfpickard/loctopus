import Foundation
import System
import UniformTypeIdentifiers

class ExportManager {
    static let shared = ExportManager()
    private let storageManager = StorageManager.shared

    private init() {}

    // MARK: - GPX Export
    func exportGPX(session: Session) -> URL? {
        let gpsSamples: [GPSSample] = storageManager.loadSensorSamples(
            sessionID: session.id,
            sensorType: .gps,
            type: GPSSample.self
        )

        guard !gpsSamples.isEmpty else { return nil }

        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Loctopus"
          xmlns="http://www.topografix.com/GPX/1/1"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <name>\(session.name)</name>
            <time>\(iso8601(session.createdAt))</time>
          </metadata>
          <trk>
            <name>\(session.name)</name>
            <trkseg>
        """

        for sample in gpsSamples {
            gpxString += """
                  <trkpt lat="\(sample.latitude)" lon="\(sample.longitude)">
                    <ele>\(sample.altitude)</ele>
                    <time>\(iso8601(sample.timestamp))</time>
                  </trkpt>
            """
        }

        gpxString += """
            </trkseg>
          </trk>
        </gpx>
        """

        return saveToTempFile(gpxString, filename: "\(session.name).gpx")
    }

    // MARK: - CSV Export
    func exportCSV(session: Session, sensorType: SensorType) -> URL? {
        var csvString = ""

        switch sensorType {
        case .gps:
            let samples: [GPSSample] = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: sensorType,
                type: GPSSample.self
            )
            csvString = "Timestamp,Latitude,Longitude,Altitude,Speed,Course,H_Accuracy,V_Accuracy\n"
            for sample in samples {
                csvString += "\(iso8601(sample.timestamp)),\(sample.latitude),\(sample.longitude),\(sample.altitude),\(sample.speed),\(sample.course),\(sample.horizontalAccuracy),\(sample.verticalAccuracy)\n"
            }

        case .accelerometer:
            let samples: [AccelerometerSample] = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: sensorType,
                type: AccelerometerSample.self
            )
            csvString = "Timestamp,X,Y,Z,Magnitude\n"
            for sample in samples {
                csvString += "\(iso8601(sample.timestamp)),\(sample.x),\(sample.y),\(sample.z),\(sample.magnitude)\n"
            }

        case .gyroscope:
            let samples: [GyroscopeSample] = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: sensorType,
                type: GyroscopeSample.self
            )
            csvString = "Timestamp,X,Y,Z\n"
            for sample in samples {
                csvString += "\(iso8601(sample.timestamp)),\(sample.x),\(sample.y),\(sample.z)\n"
            }

        case .magnetometer:
            let samples: [MagnetometerSample] = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: sensorType,
                type: MagnetometerSample.self
            )
            csvString = "Timestamp,X,Y,Z,Heading,Magnitude\n"
            for sample in samples {
                csvString += "\(iso8601(sample.timestamp)),\(sample.x),\(sample.y),\(sample.z),\(sample.heading ?? 0),\(sample.magnitude)\n"
            }

        case .barometer:
            let samples: [BarometerSample] = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: sensorType,
                type: BarometerSample.self
            )
            csvString = "Timestamp,Pressure,Relative_Altitude\n"
            for sample in samples {
                csvString += "\(iso8601(sample.timestamp)),\(sample.pressure),\(sample.relativeAltitude)\n"
            }
        }

        return saveToTempFile(csvString, filename: "\(session.name)_\(sensorType.rawValue).csv")
    }

    func exportAllCSV(session: Session) -> URL? {
        var urls: [URL] = []

        for sensor in session.sensorsEnabled {
            if let url = exportCSV(session: session, sensorType: sensor) {
                urls.append(url)
            }
        }

        guard !urls.isEmpty else { return nil }

        // Create a combined CSV or return first one
        return urls.first
    }

    // MARK: - JSON Export
    func exportJSON(session: Session) -> URL? {
        var sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "name": session.name,
            "notes": session.notes,
            "tags": session.tags,
            "createdAt": iso8601(session.createdAt),
            "duration": session.duration,
            "sensorsEnabled": session.sensorsEnabled.map { $0.rawValue }
        ]

        var sensorData: [String: [[String: Any]]] = [:]

        for sensorType in session.sensorsEnabled {
            switch sensorType {
            case .gps:
                let samples: [GPSSample] = storageManager.loadSensorSamples(
                    sessionID: session.id,
                    sensorType: sensorType,
                    type: GPSSample.self
                )
                sensorData["gps"] = samples.map { sample in
                    [
                        "timestamp": iso8601(sample.timestamp),
                        "latitude": sample.latitude,
                        "longitude": sample.longitude,
                        "altitude": sample.altitude,
                        "speed": sample.speed,
                        "course": sample.course
                    ]
                }

            case .accelerometer:
                let samples: [AccelerometerSample] = storageManager.loadSensorSamples(
                    sessionID: session.id,
                    sensorType: sensorType,
                    type: AccelerometerSample.self
                )
                sensorData["accelerometer"] = samples.map { sample in
                    [
                        "timestamp": iso8601(sample.timestamp),
                        "x": sample.x,
                        "y": sample.y,
                        "z": sample.z
                    ]
                }

            case .gyroscope:
                let samples: [GyroscopeSample] = storageManager.loadSensorSamples(
                    sessionID: session.id,
                    sensorType: sensorType,
                    type: GyroscopeSample.self
                )
                sensorData["gyroscope"] = samples.map { sample in
                    [
                        "timestamp": iso8601(sample.timestamp),
                        "x": sample.x,
                        "y": sample.y,
                        "z": sample.z
                    ]
                }

            case .magnetometer:
                let samples: [MagnetometerSample] = storageManager.loadSensorSamples(
                    sessionID: session.id,
                    sensorType: sensorType,
                    type: MagnetometerSample.self
                )
                sensorData["magnetometer"] = samples.map { sample in
                    [
                        "timestamp": iso8601(sample.timestamp),
                        "x": sample.x,
                        "y": sample.y,
                        "z": sample.z,
                        "heading": sample.heading as Any
                    ]
                }

            case .barometer:
                let samples: [BarometerSample] = storageManager.loadSensorSamples(
                    sessionID: session.id,
                    sensorType: sensorType,
                    type: BarometerSample.self
                )
                sensorData["barometer"] = samples.map { sample in
                    [
                        "timestamp": iso8601(sample.timestamp),
                        "pressure": sample.pressure,
                        "relativeAltitude": sample.relativeAltitude
                    ]
                }
            }
        }

        sessionData["sensorData"] = sensorData

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sessionData, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return saveToTempFile(jsonString, filename: "\(session.name).json")
            }
        } catch {
            print("Failed to create JSON: \(error)")
        }

        return nil
    }

    // MARK: - ZIP Export
    func exportZIP(session: Session) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var filesToZip: [URL] = []

        // Add GPX if available
        if let gpxURL = exportGPX(session: session) {
            let destination = tempDir.appendingPathComponent(gpxURL.lastPathComponent)
            try? FileManager.default.copyItem(at: gpxURL, to: destination)
            filesToZip.append(destination)
        }

        // Add all CSV files
        for sensor in session.sensorsEnabled {
            if let csvURL = exportCSV(session: session, sensorType: sensor) {
                let destination = tempDir.appendingPathComponent(csvURL.lastPathComponent)
                try? FileManager.default.copyItem(at: csvURL, to: destination)
                filesToZip.append(destination)
            }
        }

        // Add JSON
        if let jsonURL = exportJSON(session: session) {
            let destination = tempDir.appendingPathComponent(jsonURL.lastPathComponent)
            try? FileManager.default.copyItem(at: jsonURL, to: destination)
            filesToZip.append(destination)
        }

        guard !filesToZip.isEmpty else { return nil }

        // Create ZIP using FileManager's built-in archiving
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(session.name).zip")

        // Remove existing zip if present
        try? FileManager.default.removeItem(at: zipURL)

        do {
            // Use Coordinator to create a ZIP archive
            let coordinator = NSFileCoordinator()
            var error: NSError?

            coordinator.coordinate(readingItemAt: tempDir, options: [.forUploading], error: &error) { zipFileURL in
                do {
                    try FileManager.default.copyItem(at: zipFileURL, to: zipURL)
                } catch {
                    print("Failed to copy ZIP archive: \(error)")
                }
            }

            if let error = error {
                print("Failed to create ZIP: \(error)")
                return nil
            }

            // Verify ZIP was created
            if FileManager.default.fileExists(atPath: zipURL.path) {
                return zipURL
            }
        }

        // Cleanup temp directory
        try? FileManager.default.removeItem(at: tempDir)

        return nil
    }

    // MARK: - Helpers
    private func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func saveToTempFile(_ content: String, filename: String) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write file: \(error)")
            return nil
        }
    }
}
