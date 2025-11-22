import Foundation
import SwiftUI
import CoreLocation

@MainActor
class InstrumentViewModel: ObservableObject {
    @Published var sensorManager = SensorManager()
    @Published var storageManager = StorageManager.shared
    @Published var permissionManager = PermissionManager.shared

    @Published var currentSession: Session?
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    @Published var enabledSensors: Set<SensorType> = [.gps, .accelerometer, .gyroscope]

    private var recordingTimer: Timer?
    private var sessionStartTime: Date?

    // Live sensor readings for display
    @Published var currentSpeed: Double = 0
    @Published var currentAltitude: Double = 0
    @Published var currentAcceleration: Double = 0
    @Published var currentRotation: Double = 0
    @Published var currentHeading: Double = 0
    @Published var currentPressure: Double = 0

    // Statistics for current session
    private var sessionStats = SessionStatistics()

    func toggleSensor(_ sensor: SensorType) {
        if enabledSensors.contains(sensor) {
            enabledSensors.remove(sensor)
        } else {
            enabledSensors.insert(sensor)
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        // Create new session
        currentSession = storageManager.createSession(
            sensors: Array(enabledSensors)
        )

        guard let session = currentSession else { return }

        isRecording = true
        sessionStartTime = Date()
        sessionStats = SessionStatistics()

        // Setup sensor handlers
        var handlers: [SensorType: (Any) -> Void] = [:]

        if enabledSensors.contains(.gps) {
            handlers[.gps] = { [weak self] sample in
                guard let self = self, let gpsSample = sample as? GPSSample else { return }
                Task { @MainActor in
                    self.storageManager.saveSensorSample(gpsSample, sessionID: session.id, sensorType: .gps)
                    self.sessionStats.gpsSampleCount += 1

                    self.currentSpeed = gpsSample.speed
                    self.currentAltitude = gpsSample.altitude

                    if gpsSample.speed > self.sessionStats.maxSpeed {
                        self.sessionStats.maxSpeed = gpsSample.speed
                    }

                    if let minAlt = self.sessionStats.minAltitude {
                        self.sessionStats.minAltitude = min(minAlt, gpsSample.altitude)
                    } else {
                        self.sessionStats.minAltitude = gpsSample.altitude
                    }

                    if let maxAlt = self.sessionStats.maxAltitude {
                        self.sessionStats.maxAltitude = max(maxAlt, gpsSample.altitude)
                    } else {
                        self.sessionStats.maxAltitude = gpsSample.altitude
                    }
                }
            }
        }

        if enabledSensors.contains(.accelerometer) {
            handlers[.accelerometer] = { [weak self] sample in
                guard let self = self, let accelSample = sample as? AccelerometerSample else { return }
                Task { @MainActor in
                    self.storageManager.saveSensorSample(accelSample, sessionID: session.id, sensorType: .accelerometer)
                    self.sessionStats.accelerometerSampleCount += 1

                    self.currentAcceleration = accelSample.magnitude
                    if accelSample.magnitude > self.sessionStats.maxAcceleration {
                        self.sessionStats.maxAcceleration = accelSample.magnitude
                    }
                }
            }
        }

        if enabledSensors.contains(.gyroscope) {
            handlers[.gyroscope] = { [weak self] sample in
                guard let self = self, let gyroSample = sample as? GyroscopeSample else { return }
                Task { @MainActor in
                    self.storageManager.saveSensorSample(gyroSample, sessionID: session.id, sensorType: .gyroscope)
                    self.sessionStats.gyroscopeSampleCount += 1

                    let magnitude = sqrt(gyroSample.x * gyroSample.x + gyroSample.y * gyroSample.y + gyroSample.z * gyroSample.z)
                    self.currentRotation = magnitude
                }
            }
        }

        if enabledSensors.contains(.magnetometer) {
            handlers[.magnetometer] = { [weak self] sample in
                guard let self = self, let magSample = sample as? MagnetometerSample else { return }
                Task { @MainActor in
                    self.storageManager.saveSensorSample(magSample, sessionID: session.id, sensorType: .magnetometer)
                    self.sessionStats.magnetometerSampleCount += 1

                    if let heading = magSample.heading {
                        self.currentHeading = heading
                    }
                }
            }
        }

        if enabledSensors.contains(.barometer) {
            handlers[.barometer] = { [weak self] sample in
                guard let self = self, let baroSample = sample as? BarometerSample else { return }
                Task { @MainActor in
                    self.storageManager.saveSensorSample(baroSample, sessionID: session.id, sensorType: .barometer)
                    self.sessionStats.barometerSampleCount += 1

                    self.currentPressure = baroSample.pressure
                }
            }
        }

        // Start sensor recording
        sensorManager.startRecording(
            sessionID: session.id,
            sensors: enabledSensors,
            handlers: handlers
        )

        // Start UI timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(self.sessionStartTime ?? Date())
            }
        }
    }

    func stopRecording() {
        guard isRecording, let session = currentSession else { return }

        // Stop sensors
        sensorManager.stopRecording()

        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Update session
        storageManager.endSession(session)
        storageManager.updateSessionStatistics(sessionID: session.id, statistics: sessionStats)

        // Reset state
        isRecording = false
        recordingDuration = 0
        currentSession = nil
        sessionStartTime = nil
        sessionStats = SessionStatistics()

        // Reset live readings
        currentSpeed = 0
        currentAltitude = 0
        currentAcceleration = 0
        currentRotation = 0
        currentHeading = 0
        currentPressure = 0
    }
}
