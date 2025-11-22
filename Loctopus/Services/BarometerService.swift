import Foundation
import CoreMotion

final class BarometerService: ObservableObject {
    private let altimeter = CMAltimeter()
    @Published var lastSample: CMAltitudeData?
    var handler: ((CMAltitudeData) -> Void)?

    func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: OperationQueue()) { [weak self] data, error in
            if let data {
                DispatchQueue.main.async { self?.lastSample = data }
                self?.handler?(data)
            } else if let error {
                print("Altimeter error: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}
