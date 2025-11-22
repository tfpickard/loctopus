import Foundation
import CoreLocation
import CoreMotion

@MainActor
final class InstrumentViewModel: ObservableObject {
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var accelerometer: CMAccelerometerData?
    @Published var gyro: CMGyroData?
    @Published var magnetometer: CMMagnetometerData?
    @Published var barometer: CMAltitudeData?

    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
        bindLiveUpdates()
    }

    private func bindLiveUpdates() {
        appModel.locationService.locationHandler = { [weak self] location in
            DispatchQueue.main.async { self?.location = location }
        }
        appModel.locationService.headingHandler = { [weak self] heading in
            DispatchQueue.main.async { self?.heading = heading }
        }
        appModel.motionService.accelerometerHandler = { [weak self] data in
            DispatchQueue.main.async { self?.accelerometer = data }
        }
        appModel.motionService.gyroHandler = { [weak self] data in
            DispatchQueue.main.async { self?.gyro = data }
        }
        appModel.motionService.magnetometerHandler = { [weak self] data in
            DispatchQueue.main.async { self?.magnetometer = data }
        }
        appModel.barometerService.handler = { [weak self] data in
            DispatchQueue.main.async { self?.barometer = data }
        }
    }
}
