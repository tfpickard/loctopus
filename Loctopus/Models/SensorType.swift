import Foundation
import SwiftUI

enum SensorType: String, Codable, CaseIterable, Identifiable {
    case gps
    case accelerometer
    case gyroscope
    case magnetometer
    case barometer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gps: return "GPS"
        case .accelerometer: return "Accelerometer"
        case .gyroscope: return "Gyroscope"
        case .magnetometer: return "Magnetometer"
        case .barometer: return "Barometer"
        }
    }

    var systemImage: String {
        switch self {
        case .gps: return "location.fill"
        case .accelerometer: return "waveform.path"
        case .gyroscope: return "gyroscope"
        case .magnetometer: return "scope"
        case .barometer: return "gauge"
        }
    }

    var accentColor: Color {
        switch self {
        case .gps: return .cyan
        case .accelerometer: return .orange
        case .gyroscope: return .purple
        case .magnetometer: return .green
        case .barometer: return .blue
        }
    }
}
