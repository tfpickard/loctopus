import Foundation
import CoreLocation

// MARK: - Base Protocol
protocol SensorSample: Codable {
    var timestamp: Date { get }
}

// MARK: - GPS Data
struct GPSSample: SensorSample {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let speed: Double
    let course: Double
}

extension GPSSample {
    init(location: CLLocation) {
        self.timestamp = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.speed = location.speed
        self.course = location.course
    }
}

// MARK: - Accelerometer Data
struct AccelerometerSample: SensorSample {
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double

    var magnitude: Double {
        sqrt(x * x + y * y + z * z)
    }
}

// MARK: - Gyroscope Data
struct GyroscopeSample: SensorSample {
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}

// MARK: - Magnetometer Data
struct MagnetometerSample: SensorSample {
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
    let heading: Double?

    var magnitude: Double {
        sqrt(x * x + y * y + z * z)
    }
}

// MARK: - Barometer Data
struct BarometerSample: SensorSample {
    let timestamp: Date
    let pressure: Double // kPa
    let relativeAltitude: Double // meters
}

// MARK: - Session Statistics
struct SessionStatistics: Codable {
    var gpsSampleCount: Int = 0
    var accelerometerSampleCount: Int = 0
    var gyroscopeSampleCount: Int = 0
    var magnetometerSampleCount: Int = 0
    var barometerSampleCount: Int = 0

    var totalDistance: Double = 0 // meters
    var maxSpeed: Double = 0 // m/s
    var minAltitude: Double?
    var maxAltitude: Double?
    var maxAcceleration: Double = 0
}
