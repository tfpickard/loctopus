import SwiftUI
import MapKit

struct RecordingView: View {
    @ObservedObject var viewModel: InstrumentViewModel
    @Binding var isPresented: Bool

    @State private var sessionName: String = ""
    @State private var selectedPage = 0
    @State private var showingStopConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                TabView(selection: $selectedPage) {
                    if viewModel.enabledSensors.contains(.gps) {
                        gpsPage.tag(0)
                    }

                    if viewModel.enabledSensors.contains(.accelerometer) {
                        accelerometerPage.tag(1)
                    }

                    if viewModel.enabledSensors.contains(.gyroscope) {
                        gyroscopePage.tag(2)
                    }

                    if viewModel.enabledSensors.contains(.magnetometer) {
                        magnetometerPage.tag(3)
                    }

                    if viewModel.enabledSensors.contains(.barometer) {
                        barometerPage.tag(4)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                bottomBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stop") {
                        showingStopConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .confirmationDialog("Stop Recording?", isPresented: $showingStopConfirmation) {
                Button("Stop & Save", role: .destructive) {
                    stopRecording()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .onAppear {
            sessionName = viewModel.currentSession?.name ?? "Session"
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(formattedDuration)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.red)

            TextField("Session Name", text: $sessionName)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .onChange(of: sessionName) { _, newValue in
                    if var session = viewModel.currentSession {
                        session.name = newValue
                        viewModel.currentSession = session
                    }
                }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var gpsPage: some View {
        VStack {
            Text("GPS")
                .font(.title2.bold())
                .padding()

            // Simplified map placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Map View")
                            .foregroundColor(.secondary)
                    }
                )
                .padding()

            VStack(spacing: 12) {
                MetricRow(label: "Speed", value: String(format: "%.1f m/s", viewModel.currentSpeed))
                MetricRow(label: "Altitude", value: String(format: "%.1f m", viewModel.currentAltitude))
            }
            .padding()

            Spacer()
        }
    }

    private var accelerometerPage: some View {
        VStack {
            Text("Accelerometer")
                .font(.title2.bold())
                .padding()

            VStack(alignment: .leading, spacing: 8) {
                Text("3-Axis Acceleration")
                    .font(.caption)
                    .foregroundColor(.secondary)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 150)
                    .overlay(
                        Text("Live Graph")
                            .foregroundColor(.secondary)
                    )
            }
            .padding()

            MetricRow(label: "Magnitude", value: String(format: "%.3f g", viewModel.currentAcceleration))
                .padding()

            Spacer()
        }
    }

    private var gyroscopePage: some View {
        VStack {
            Text("Gyroscope")
                .font(.title2.bold())
                .padding()

            VStack(alignment: .leading, spacing: 8) {
                Text("3-Axis Rotation Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 150)
                    .overlay(
                        Text("Live Graph")
                            .foregroundColor(.secondary)
                    )
            }
            .padding()

            MetricRow(label: "Rotation", value: String(format: "%.3f rad/s", viewModel.currentRotation))
                .padding()

            Spacer()
        }
    }

    private var magnetometerPage: some View {
        VStack {
            Text("Magnetometer")
                .font(.title2.bold())
                .padding()

            CompassView(heading: viewModel.currentHeading)
                .padding()

            MetricRow(label: "Heading", value: String(format: "%.0f°", viewModel.currentHeading))
                .padding()

            Spacer()
        }
    }

    private var barometerPage: some View {
        VStack {
            Text("Barometer")
                .font(.title2.bold())
                .padding()

            VStack(alignment: .leading, spacing: 8) {
                Text("Atmospheric Pressure")
                    .font(.caption)
                    .foregroundColor(.secondary)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 150)
                    .overlay(
                        Text("Live Graph")
                            .foregroundColor(.secondary)
                    )
            }
            .padding()

            MetricRow(label: "Pressure", value: String(format: "%.2f kPa", viewModel.currentPressure))
                .padding()

            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            ForEach(Array(viewModel.enabledSensors), id: \.self) { sensor in
                VStack {
                    Image(systemName: sensor.icon)
                        .font(.caption)
                    Text(sensor.rawValue)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var formattedDuration: String {
        let duration = viewModel.recordingDuration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func stopRecording() {
        viewModel.stopRecording()
        isPresented = false
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .bold()
        }
        .padding(.horizontal)
    }
}
