import SwiftUI

struct InstrumentDashboardView: View {
    @StateObject private var viewModel = InstrumentViewModel()
    @State private var showingRecordingView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !viewModel.permissionManager.hasLocationPermission && viewModel.enabledSensors.contains(.gps) {
                        permissionBanner
                    }

                    recordingButton

                    sensorGrid

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Loctopus")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    storageIndicator
                }
            }
            .fullScreenCover(isPresented: $showingRecordingView) {
                RecordingView(viewModel: viewModel, isPresented: $showingRecordingView)
            }
        }
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Location Permission Required")
                    .font(.headline)
            }

            Text(viewModel.permissionManager.locationPermissionDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Grant Permission") {
                viewModel.permissionManager.requestLocationPermission(locationManager: viewModel.sensorManager.locationManager)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var recordingButton: some View {
        Button {
            startRecording()
        } label: {
            HStack {
                Image(systemName: "record.circle.fill")
                    .font(.title2)
                Text("Start Recording")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(viewModel.enabledSensors.isEmpty)
        .opacity(viewModel.enabledSensors.isEmpty ? 0.5 : 1.0)
    }

    private var sensorGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(SensorType.allCases) { sensor in
                SensorCardView(
                    sensorType: sensor,
                    isEnabled: viewModel.enabledSensors.contains(sensor),
                    isRecording: viewModel.isRecording,
                    currentValue: getCurrentValue(for: sensor),
                    action: {
                        withAnimation {
                            viewModel.toggleSensor(sensor)
                        }
                    }
                )
            }
        }
    }

    private var storageIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: CloudKitManager.shared.isSyncEnabled ? "icloud.fill" : "internaldrive.fill")
                .font(.caption)
            Text(CloudKitManager.shared.isSyncEnabled ? "iCloud" : "Local")
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }

    private func getCurrentValue(for sensor: SensorType) -> String {
        switch sensor {
        case .gps:
            return String(format: "%.1f m/s", viewModel.currentSpeed)
        case .accelerometer:
            return String(format: "%.2f g", viewModel.currentAcceleration)
        case .gyroscope:
            return String(format: "%.2f rad/s", viewModel.currentRotation)
        case .magnetometer:
            return String(format: "%.0f°", viewModel.currentHeading)
        case .barometer:
            return String(format: "%.1f kPa", viewModel.currentPressure)
        }
    }

    private func startRecording() {
        viewModel.startRecording()
        showingRecordingView = true
    }
}
