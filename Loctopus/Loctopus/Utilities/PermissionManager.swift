import Foundation
import CoreLocation
import UIKit

@MainActor
class PermissionManager: ObservableObject {
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var motionPermissionGranted: Bool = true // Motion doesn't require explicit permission on iOS

    static let shared = PermissionManager()

    private init() {}

    func checkPermissions(locationManager: LocationManager) {
        locationPermissionStatus = locationManager.authorizationStatus
    }

    func requestLocationPermission(locationManager: LocationManager) {
        locationManager.requestAuthorization()
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    var hasLocationPermission: Bool {
        locationPermissionStatus == .authorizedAlways ||
        locationPermissionStatus == .authorizedWhenInUse
    }

    var locationPermissionDescription: String {
        switch locationPermissionStatus {
        case .notDetermined:
            return "Location permission not yet requested"
        case .restricted:
            return "Location access is restricted"
        case .denied:
            return "Location permission denied. Enable in Settings to record GPS data."
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location permission granted"
        @unknown default:
            return "Unknown location permission status"
        }
    }
}
