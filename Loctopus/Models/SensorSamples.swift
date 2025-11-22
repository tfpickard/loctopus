import Foundation
import CoreLocation

struct GPSSample: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var speed: Double
    var course: Double
    var horizontalAccuracy: Double
}

struct MotionSample: Codable, Hashable {
    var timestamp: Date
    var x: Double
    var y: Double
    var z: Double
}

struct BarometerSample: Codable, Hashable {
    var timestamp: Date
    var pressure: Double
    var relativeAltitude: Double?
}

struct SessionExport: Codable {
    var session: Session
    var gps: [GPSSample]
    var accelerometer: [MotionSample]
    var gyroscope: [MotionSample]
    var magnetometer: [MotionSample]
    var barometer: [BarometerSample]
}
