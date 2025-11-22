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

    // Live data history for graphs (limited to recent samples)
    @Published var recordedGPSCoordinates: [CLLocationCoordinate2D] = []
    @Published var accelXHistory: [Double] = []
    @Published var accelYHistory: [Double] = []
    @Published var accelZHistory: [Double] = []
    @Published var gyroXHistory: [Double] = []
    @Published var gyroYHistory: [Double] = []
    @Published var gyroZHistory: [Double] = []
    @Published var pressureHistory: [Double] = []

    private let maxHistoryPoints = 100

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

                    // Add to GPS coordinates
                    let coordinate = CLLocationCoordinate2D(
                        latitude: gpsSample.latitude,
                        longitude: gpsSample.longitude
                    )
                    self.recordedGPSCoordinates.append(coordinate)

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

                    // Add to history
                    self.accelXHistory.append(accelSample.x)
                    self.accelYHistory.append(accelSample.y)
                    self.accelZHistory.append(accelSample.z)

                    // Limit history size
                    if self.accelXHistory.count > self.maxHistoryPoints {
                        self.accelXHistory.removeFirst()
                        self.accelYHistory.removeFirst()
                        self.accelZHistory.removeFirst()
                    }

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

                    // Add to history
                    self.gyroXHistory.append(gyroSample.x)
                    self.gyroYHistory.append(gyroSample.y)
                    self.gyroZHistory.append(gyroSample.z)

                    // Limit history size
                    if self.gyroXHistory.count > self.maxHistoryPoints {
                        self.gyroXHistory.removeFirst()
                        self.gyroYHistory.removeFirst()
                        self.gyroZHistory.removeFirst()
                    }
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

                    // Add to history
                    self.pressureHistory.append(baroSample.pressure)

                    // Limit history size
                    if self.pressureHistory.count > self.maxHistoryPoints {
                        self.pressureHistory.removeFirst()
                    }
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

        // Clear history
        recordedGPSCoordinates.removeAll()
        accelXHistory.removeAll()
        accelYHistory.removeAll()
        accelZHistory.removeAll()
        gyroXHistory.removeAll()
        gyroYHistory.removeAll()
        gyroZHistory.removeAll()
        pressureHistory.removeAll()
    }
}
