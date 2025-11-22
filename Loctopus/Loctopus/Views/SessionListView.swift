import SwiftUI

struct SessionListView: View {
    @StateObject private var viewModel = SessionListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredSessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Sessions")
            .searchable(text: $viewModel.searchText, prompt: "Search sessions")
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Sessions")
                .font(.title2.bold())

            Text("Start recording to create your first session")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var sessionList: some View {
        List {
            ForEach(viewModel.filteredSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    SessionRowView(session: session)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteSession(session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        // Export action
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.name)
                    .font(.headline)

                Spacer()

                if session.isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Text(session.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(session.sensorsEnabled, id: \.self) { sensor in
                        Image(systemName: sensor.icon)
                            .font(.caption)
                            .foregroundColor(sensorColor(sensor))
                    }
                }
            }

            if !session.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(session.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
