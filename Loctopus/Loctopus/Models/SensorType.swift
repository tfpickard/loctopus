import Foundation

enum SensorType: String, CaseIterable, Codable, Identifiable {
    case gps = "GPS"
    case accelerometer = "Accelerometer"
    case gyroscope = "Gyroscope"
    case magnetometer = "Magnetometer"
    case barometer = "Barometer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gps: return "location.fill"
        case .accelerometer: return "arrow.up.and.down.and.arrow.left.and.right"
        case .gyroscope: return "gyroscope"
        case .magnetometer: return "compass.drawing"
        case .barometer: return "barometer"
        }
    }

    var accentColor: String {
        switch self {
        case .gps: return "cyan"
        case .accelerometer: return "green"
        case .gyroscope: return "orange"
        case .magnetometer: return "purple"
        case .barometer: return "blue"
        }
    }

    var description: String {
        switch self {
        case .gps: return "Position, speed, altitude"
        case .accelerometer: return "3-axis acceleration"
        case .gyroscope: return "3-axis rotation"
        case .magnetometer: return "Magnetic field & heading"
        case .barometer: return "Atmospheric pressure"
        }
    }
}
