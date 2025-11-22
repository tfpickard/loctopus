import Foundation
import SwiftUI
import CoreLocation

@MainActor
class SessionDetailViewModel: ObservableObject {
    @Published var session: Session
    @Published var storageManager = StorageManager.shared
    @Published var exportManager = ExportManager.shared

    @Published var isExporting = false
    @Published var shareItem: URL?

    // Loaded sensor data
    @Published var gpsData: [GPSSample] = []
    @Published var accelerometerData: [AccelerometerSample] = []
    @Published var gyroscopeData: [GyroscopeSample] = []
    @Published var magnetometerData: [MagnetometerSample] = []
    @Published var barometerData: [BarometerSample] = []

    init(session: Session) {
        self.session = session
        loadSensorData()
    }

    func loadSensorData() {
        if session.sensorsEnabled.contains(.gps) {
            gpsData = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: .gps,
                type: GPSSample.self
            )
        }

        if session.sensorsEnabled.contains(.accelerometer) {
            accelerometerData = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: .accelerometer,
                type: AccelerometerSample.self
            )
        }

        if session.sensorsEnabled.contains(.gyroscope) {
            gyroscopeData = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: .gyroscope,
                type: GyroscopeSample.self
            )
        }

        if session.sensorsEnabled.contains(.magnetometer) {
            magnetometerData = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: .magnetometer,
                type: MagnetometerSample.self
            )
        }

        if session.sensorsEnabled.contains(.barometer) {
            barometerData = storageManager.loadSensorSamples(
                sessionID: session.id,
                sensorType: .barometer,
                type: BarometerSample.self
            )
        }
    }

    func updateSession() {
        storageManager.updateSession(session)
    }

    func exportGPX() {
        guard let url = exportManager.exportGPX(session: session) else { return }
        shareItem = url
    }

    func exportCSV(sensorType: SensorType) {
        guard let url = exportManager.exportCSV(session: session, sensorType: sensorType) else { return }
        shareItem = url
    }

    func exportJSON() {
        guard let url = exportManager.exportJSON(session: session) else { return }
        shareItem = url
    }

    func exportZIP() {
        guard let url = exportManager.exportZIP(session: session) else { return }
        shareItem = url
    }

    // Computed statistics
    var totalDistance: Double {
        guard !gpsData.isEmpty else { return 0 }

        var distance: Double = 0
        for i in 1..<gpsData.count {
            let prev = CLLocation(
                latitude: gpsData[i-1].latitude,
                longitude: gpsData[i-1].longitude
            )
            let curr = CLLocation(
                latitude: gpsData[i].latitude,
                longitude: gpsData[i].longitude
            )
            distance += curr.distance(from: prev)
        }
        return distance
    }

    var averageSpeed: Double {
        guard !gpsData.isEmpty else { return 0 }
        let validSpeeds = gpsData.filter { $0.speed >= 0 }
        guard !validSpeeds.isEmpty else { return 0 }
        return validSpeeds.map { $0.speed }.reduce(0, +) / Double(validSpeeds.count)
    }

    var maxSpeed: Double {
        gpsData.map { $0.speed }.max() ?? 0
    }

    var altitudeRange: (min: Double, max: Double)? {
        guard !gpsData.isEmpty else { return nil }
        let altitudes = gpsData.map { $0.altitude }
        guard let min = altitudes.min(), let max = altitudes.max() else { return nil }
        return (min, max)
    }
}
