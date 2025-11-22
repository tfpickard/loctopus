import Foundation
import CoreLocation
import Combine

@MainActor
class SensorManager: ObservableObject {
    @Published var enabledSensors: Set<SensorType> = []
    @Published var isRecording = false

    let locationManager = LocationManager()
    let motionManager = MotionManager()

    private var currentSessionID: UUID?
    private var sampleHandlers: [SensorType: (Any) -> Void] = [:]

    func isSensorAvailable(_ sensor: SensorType) -> Bool {
        switch sensor {
        case .gps:
            return true // Always available, but may not have permission
        case .accelerometer:
            return motionManager.isAccelerometerAvailable
        case .gyroscope:
            return motionManager.isGyroAvailable
        case .magnetometer:
            return motionManager.isMagnetometerAvailable
        case .barometer:
            return motionManager.isBarometerAvailable
        }
    }

    func toggleSensor(_ sensor: SensorType) {
        if enabledSensors.contains(sensor) {
            enabledSensors.remove(sensor)
        } else {
            enabledSensors.insert(sensor)
        }
    }

    func startRecording(
        sessionID: UUID,
        sensors: Set<SensorType>,
        handlers: [SensorType: (Any) -> Void]
    ) {
        currentSessionID = sessionID
        sampleHandlers = handlers
        isRecording = true

        if sensors.contains(.gps) {
            locationManager.startUpdatingLocation { [weak self] location in
                guard let self = self else { return }
                let sample = GPSSample(location: location)
                Task { @MainActor in
                    self.sampleHandlers[.gps]?(sample)
                }
            }

            locationManager.setHeadingUpdateHandler { [weak self] heading in
                guard let self = self else { return }
                Task { @MainActor in
                    // Heading is incorporated into magnetometer samples
                }
            }
        }

        if sensors.contains(.accelerometer) {
            motionManager.startAccelerometerUpdates { [weak self] sample in
                self?.sampleHandlers[.accelerometer]?(sample)
            }
        }

        if sensors.contains(.gyroscope) {
            motionManager.startGyroscopeUpdates { [weak self] sample in
                self?.sampleHandlers[.gyroscope]?(sample)
            }
        }

        if sensors.contains(.magnetometer) {
            motionManager.startMagnetometerUpdates(
                heading: locationManager.currentHeading?.trueHeading
            ) { [weak self] sample in
                self?.sampleHandlers[.magnetometer]?(sample)
            }
        }

        if sensors.contains(.barometer) {
            motionManager.startBarometerUpdates { [weak self] sample in
                self?.sampleHandlers[.barometer]?(sample)
            }
        }
    }

    func stopRecording() {
        locationManager.stopUpdatingLocation()
        motionManager.stopAllUpdates()
        sampleHandlers.removeAll()
        currentSessionID = nil
        isRecording = false
    }

    func getCurrentHeading() -> Double? {
        locationManager.currentHeading?.trueHeading
    }
}
