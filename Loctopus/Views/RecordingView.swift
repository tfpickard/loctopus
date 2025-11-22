import SwiftUI
import MapKit

struct RecordingView: View {
    @EnvironmentObject var recordingModel: RecordingViewModel
    @EnvironmentObject var appModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State var sessionName: String = "Session at " + Date().formatted(date: .numeric, time: .shortened)
    let selectedSensors: [SensorType]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    TextField("Session name", text: $sessionName)
                        .textFieldStyle(.roundedBorder)
                    Text(timerString)
                        .font(.title.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive, action: stop) {
                    Label("Stop", systemImage: "stop.fill")
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
            }
            TabView {
                gpsPage
                    .tabItem { Label("GPS", systemImage: "map") }
                motionPage(title: "Accelerometer", samples: recordingModel.accelSamples)
                    .tabItem { Label("Accel", systemImage: "waveform.path") }
                motionPage(title: "Gyroscope", samples: recordingModel.gyroSamples)
                    .tabItem { Label("Gyro", systemImage: "gyroscope") }
                motionPage(title: "Magnetometer", samples: recordingModel.magnetometerSamples)
                    .tabItem { Label("Mag", systemImage: "scope") }
                barometerPage
                    .tabItem { Label("Baro", systemImage: "gauge") }
            }
            .tabViewStyle(.page)
            HStack { ForEach(selectedSensors, id: \.self) { SensorBadgeView(sensor: $0) } }
        }
        .padding()
        .onAppear {
            recordingModel.startSession(name: sessionName, sensors: selectedSensors)
        }
    }

    private var timerString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: recordingModel.elapsed) ?? "00:00:00"
    }

    private var gpsPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let sample = recordingModel.gpsSamples.last {
                Map(initialPosition: .region(.init(center: CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))))
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                StatRow(title: "Speed", value: String(format: "%.2f m/s", sample.speed))
                StatRow(title: "Altitude", value: String(format: "%.1f m", sample.altitude))
                StatRow(title: "Accuracy", value: String(format: "±%.1f m", sample.horizontalAccuracy))
            } else {
                Text("Waiting for GPS…")
            }
        }
    }

    private func motionPage(title: String, samples: [MotionSample]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            if let sample = samples.last {
                Text(String(format: "x %.2f y %.2f z %.2f", sample.x, sample.y, sample.z))
                    .font(.title3.monospacedDigit())
            }
            RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                .frame(height: 160)
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        .mask(AnimatedWave(samples: samples.map { $0.x }))
                        .animation(.easeInOut(duration: 0.4), value: samples.count)
                        .padding(8)
                }
        }
    }

    private var barometerPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Barometer")
                .font(.headline)
            if let sample = recordingModel.baroSamples.last {
                Text(String(format: "Pressure %.2f kPa", sample.pressure))
                if let altitude = sample.relativeAltitude {
                    Text(String(format: "Δ Altitude %.2f m", altitude))
                }
            }
            RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                .frame(height: 160)
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(colors: [.cyan.opacity(0.6), .indigo.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        .mask(AnimatedWave(samples: recordingModel.baroSamples.map { $0.pressure }))
                        .animation(.easeInOut(duration: 0.4), value: recordingModel.baroSamples.count)
                        .padding(8)
                }
        }
    }

    private func stop() {
        recordingModel.stopSession()
        dismiss()
    }
}

struct AnimatedWave: Shape {
    var samples: [Double]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard samples.count > 1 else { return path }
        let step = rect.width / CGFloat(samples.count - 1)
        let values = samples.suffix(60)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 1
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * step
            let normalized = (value - minVal) / max(0.0001, (maxVal - minVal))
            let y = rect.height - CGFloat(normalized) * rect.height
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path.strokedPath(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}
