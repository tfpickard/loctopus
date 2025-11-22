import SwiftUI
import MapKit

struct SessionDetailView: View {
    @StateObject private var viewModel: SessionDetailViewModel
    @State private var isEditingName = false
    @State private var isEditingNotes = false
    @State private var showingShareSheet = false

    init(session: Session) {
        _viewModel = StateObject(wrappedValue: SessionDetailViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sessionHeader

                if !viewModel.session.notes.isEmpty || isEditingNotes {
                    notesSection
                }

                tagsSection

                statsSection

                if !viewModel.gpsData.isEmpty {
                    gpsSection
                }

                if !viewModel.accelerometerData.isEmpty {
                    accelerometerSection
                }

                if !viewModel.gyroscopeData.isEmpty {
                    gyroscopeSection
                }

                if !viewModel.magnetometerData.isEmpty {
                    magnetometerSection
                }

                if !viewModel.barometerData.isEmpty {
                    barometerSection
                }

                exportSection
            }
            .padding()
        }
        .navigationTitle(viewModel.session.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = viewModel.shareItem {
                ShareSheet(items: [url])
            }
        }
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditingName {
                TextField("Session Name", text: $viewModel.session.name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        isEditingName = false
                        viewModel.updateSession()
                    }
            } else {
                HStack {
                    Text(viewModel.session.name)
                        .font(.title2.bold())
                    Button {
                        isEditingName = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                }
            }

            Text(viewModel.session.formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Label(viewModel.session.formattedDuration, systemImage: "clock")
                    .font(.subheadline)

                Spacer()

                ForEach(viewModel.session.sensorsEnabled, id: \.self) { sensor in
                    Image(systemName: sensor.icon)
                        .foregroundColor(sensorColor(sensor))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            if isEditingNotes {
                TextEditor(text: $viewModel.session.notes)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onSubmit {
                        isEditingNotes = false
                        viewModel.updateSession()
                    }
            } else {
                Text(viewModel.session.notes.isEmpty ? "Add notes..." : viewModel.session.notes)
                    .foregroundColor(viewModel.session.notes.isEmpty ? .secondary : .primary)
                    .onTapGesture {
                        isEditingNotes = true
                    }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            if viewModel.session.tags.isEmpty {
                Text("No tags")
                    .foregroundColor(.secondary)
                    .font(.callout)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.session.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.callout)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "GPS Samples",
                    value: "\(viewModel.session.statistics.gpsSampleCount)"
                )

                StatCard(
                    title: "Motion Samples",
                    value: "\(viewModel.session.statistics.accelerometerSampleCount)"
                )

                if viewModel.totalDistance > 0 {
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.2f km", viewModel.totalDistance / 1000)
                    )
                }

                if viewModel.maxSpeed > 0 {
                    StatCard(
                        title: "Max Speed",
                        value: String(format: "%.1f m/s", viewModel.maxSpeed)
                    )
                }
            }
        }
    }

    private var gpsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GPS Track")
                .font(.headline)

            // Map placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.gpsData.count) GPS points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )

            HStack {
                if let range = viewModel.altitudeRange {
                    VStack(alignment: .leading) {
                        Text("Altitude Range")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(range.min))m - \(Int(range.max))m")
                            .font(.callout.bold())
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Avg Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f m/s", viewModel.averageSpeed))
                        .font(.callout.bold())
                }
            }
        }
    }

    private var accelerometerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accelerometer")
                .font(.headline)

            Text("\(viewModel.accelerometerData.count) samples")
                .font(.caption)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay(
                    Text("Graph Preview")
                        .foregroundColor(.secondary)
                )
        }
    }

    private var gyroscopeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gyroscope")
                .font(.headline)

            Text("\(viewModel.gyroscopeData.count) samples")
                .font(.caption)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay(
                    Text("Graph Preview")
                        .foregroundColor(.secondary)
                )
        }
    }

    private var magnetometerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Magnetometer")
                .font(.headline)

            Text("\(viewModel.magnetometerData.count) samples")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var barometerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Barometer")
                .font(.headline)

            Text("\(viewModel.barometerData.count) samples")
                .font(.caption)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay(
                    Text("Pressure Graph")
                        .foregroundColor(.secondary)
                )
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline)

            VStack(spacing: 8) {
                if viewModel.session.sensorsEnabled.contains(.gps) {
                    ExportButton(title: "Export GPX", icon: "map") {
                        viewModel.exportGPX()
                        showingShareSheet = true
                    }
                }

                ExportButton(title: "Export CSV", icon: "doc.text") {
                    if let firstSensor = viewModel.session.sensorsEnabled.first {
                        viewModel.exportCSV(sensorType: firstSensor)
                        showingShareSheet = true
                    }
                }

                ExportButton(title: "Export JSON", icon: "doc.text") {
                    viewModel.exportJSON()
                    showingShareSheet = true
                }

                ExportButton(title: "Export All (ZIP)", icon: "doc.zipper") {
                    viewModel.exportZIP()
                    showingShareSheet = true
                }
            }
        }
    }

    private func sensorColor(_ sensor: SensorType) -> Color {
        switch sensor {
        case .gps: return .cyan
        case .accelerometer: return .green
        case .gyroscope: return .orange
        case .magnetometer: return .purple
        case .barometer: return .blue
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "square.and.arrow.up")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
