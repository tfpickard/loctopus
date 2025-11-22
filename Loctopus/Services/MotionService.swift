import Foundation
import CoreMotion

final class MotionService: ObservableObject {
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    @Published var lastAccelerometer: CMAccelerometerData?
    @Published var lastGyro: CMGyroData?
    @Published var lastMagnetometer: CMMagnetometerData?

    var accelerometerHandler: ((CMAccelerometerData) -> Void)?
    var gyroHandler: ((CMGyroData) -> Void)?
    var magnetometerHandler: ((CMMagnetometerData) -> Void)?

    init() {
        queue.qualityOfService = .userInitiated
    }

    func start(accelerometer: Bool, gyro: Bool, magnetometer: Bool, interval: TimeInterval = 1.0 / 30.0) {
        if accelerometer, manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = interval
            manager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
                guard let data else { return }
                DispatchQueue.main.async { self?.lastAccelerometer = data }
                self?.accelerometerHandler?(data)
            }
        }
        if gyro, manager.isGyroAvailable {
            manager.gyroUpdateInterval = interval
            manager.startGyroUpdates(to: queue) { [weak self] data, _ in
                guard let data else { return }
                DispatchQueue.main.async { self?.lastGyro = data }
                self?.gyroHandler?(data)
            }
        }
        if magnetometer, manager.isMagnetometerAvailable {
            manager.magnetometerUpdateInterval = interval
            manager.startMagnetometerUpdates(to: queue) { [weak self] data, _ in
                guard let data else { return }
                DispatchQueue.main.async { self?.lastMagnetometer = data }
                self?.magnetometerHandler?(data)
            }
        }
    }

    func stop() {
        manager.stopAccelerometerUpdates()
        manager.stopGyroUpdates()
        manager.stopMagnetometerUpdates()
    }
}
