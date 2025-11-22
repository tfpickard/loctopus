import Foundation
import CoreMotion
import Combine

@MainActor
class MotionManager: ObservableObject {
    @Published var isAccelerometerAvailable: Bool
    @Published var isGyroAvailable: Bool
    @Published var isMagnetometerAvailable: Bool
    @Published var isBarometerAvailable: Bool

    @Published var currentAcceleration: CMAcceleration?
    @Published var currentRotation: CMRotationRate?
    @Published var currentMagneticField: CMMagneticField?
    @Published var currentPressure: Double?
    @Published var currentRelativeAltitude: Double?

    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private var accelerometerHandler: ((AccelerometerSample) -> Void)?
    private var gyroscopeHandler: ((GyroscopeSample) -> Void)?
    private var magnetometerHandler: ((MagnetometerSample) -> Void)?
    private var barometerHandler: ((BarometerSample) -> Void)?

    private let updateInterval: TimeInterval = 0.1 // 10 Hz

    init() {
        isAccelerometerAvailable = motionManager.isAccelerometerAvailable
        isGyroAvailable = motionManager.isGyroAvailable
        isMagnetometerAvailable = motionManager.isMagnetometerAvailable
        isBarometerAvailable = CMAltimeter.isRelativeAltitudeAvailable()

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        motionManager.magnetometerUpdateInterval = updateInterval
    }

    // MARK: - Accelerometer
    func startAccelerometerUpdates(handler: @escaping (AccelerometerSample) -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }

        accelerometerHandler = handler
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }

            Task { @MainActor in
                self?.currentAcceleration = data.acceleration
                let sample = AccelerometerSample(
                    timestamp: Date(),
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z
                )
                handler(sample)
            }
        }
    }

    func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
        accelerometerHandler = nil
    }

    // MARK: - Gyroscope
    func startGyroscopeUpdates(handler: @escaping (GyroscopeSample) -> Void) {
        guard motionManager.isGyroAvailable else { return }

        gyroscopeHandler = handler
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }

            Task { @MainActor in
                self?.currentRotation = data.rotationRate
                let sample = GyroscopeSample(
                    timestamp: Date(),
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z
                )
                handler(sample)
            }
        }
    }

    func stopGyroscopeUpdates() {
        motionManager.stopGyroUpdates()
        gyroscopeHandler = nil
    }

    // MARK: - Magnetometer
    func startMagnetometerUpdates(heading: Double? = nil, handler: @escaping (MagnetometerSample) -> Void) {
        guard motionManager.isMagnetometerAvailable else { return }

        magnetometerHandler = handler
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }

            Task { @MainActor in
                self?.currentMagneticField = data.magneticField
                let sample = MagnetometerSample(
                    timestamp: Date(),
                    x: data.magneticField.x,
                    y: data.magneticField.y,
                    z: data.magneticField.z,
                    heading: heading
                )
                handler(sample)
            }
        }
    }

    func stopMagnetometerUpdates() {
        motionManager.stopMagnetometerUpdates()
        magnetometerHandler = nil
    }

    // MARK: - Barometer
    func startBarometerUpdates(handler: @escaping (BarometerSample) -> Void) {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }

        barometerHandler = handler
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }

            Task { @MainActor in
                self?.currentPressure = data.pressure.doubleValue
                self?.currentRelativeAltitude = data.relativeAltitude.doubleValue
                let sample = BarometerSample(
                    timestamp: Date(),
                    pressure: data.pressure.doubleValue,
                    relativeAltitude: data.relativeAltitude.doubleValue
                )
                handler(sample)
            }
        }
    }

    func stopBarometerUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
        barometerHandler = nil
    }

    // MARK: - Stop All
    func stopAllUpdates() {
        stopAccelerometerUpdates()
        stopGyroscopeUpdates()
        stopMagnetometerUpdates()
        stopBarometerUpdates()
    }
}
