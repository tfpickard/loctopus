import SwiftUI
import CoreLocation
import CoreMotion

struct SensorCardView: View {
    let sensor: SensorType
    var location: CLLocation?
    var heading: CLHeading?
    var accelerometer: CMAccelerometerData?
    var gyro: CMGyroData?
    var magnetometer: CMMagnetometerData?
    var barometer: CMAltitudeData?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(sensor.displayName, systemImage: sensor.systemImage)
                    .foregroundStyle(sensor.accentColor)
                Spacer()
            }
            preview
                .font(.footnote.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var preview: some View {
        switch sensor {
        case .gps:
            if let location {
                Text(String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))
            } else { Text("Awaiting fix…") }
        case .accelerometer:
            if let a = accelerometer {
                Text(String(format: "x %.2f y %.2f z %.2f", a.acceleration.x, a.acceleration.y, a.acceleration.z))
            } else { Text("Idle") }
        case .gyroscope:
            if let g = gyro {
                Text(String(format: "x %.2f y %.2f z %.2f", g.rotationRate.x, g.rotationRate.y, g.rotationRate.z))
            } else { Text("Idle") }
        case .magnetometer:
            if let heading {
                Text(String(format: "Heading %.0f°", heading.trueHeading))
            } else if let mag = magnetometer {
                Text(String(format: "x %.1f y %.1f z %.1f", mag.magneticField.x, mag.magneticField.y, mag.magneticField.z))
            } else { Text("Idle") }
        case .barometer:
            if let baro = barometer {
                Text(String(format: "%.2f kPa", baro.pressure.doubleValue))
            } else { Text("Idle") }
        }
    }
}
