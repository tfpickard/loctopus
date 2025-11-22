import SwiftUI
import MapKit

struct SessionsListView: View {
    @EnvironmentObject var appModel: AppViewModel
    @StateObject private var viewModel: SessionsViewModel
    @State private var shareURL: URL?

    init(appModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: SessionsViewModel(appModel: appModel))
    }

    var body: some View {
        List {
            ForEach(viewModel.filteredSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    SessionRow(session: session)
                }
                .swipeActions {
                    Button(role: .destructive) { Task { await viewModel.delete(session) } } label: { Label("Delete", systemImage: "trash") }
                    Button { Task { shareURL = try? await appModel.exportService.exportZIP(session: session, store: appModel.sessionStore) } } label: { Label("Export", systemImage: "square.and.arrow.up") }
                        .tint(.blue)
                }
            }
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Sessions")
        .task { await viewModel.load() }
        .sheet(item: $shareURL) { url in
            ShareView(url: url)
        }
    }
}

private struct ShareView: View, Identifiable {
    let url: URL
    var id: URL { url }
    var body: some View { ShareLink(item: url) { Label("Export", systemImage: "square.and.arrow.up") } }
}

struct SessionRow: View {
    let session: Session
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name)
                    .font(.headline)
                Spacer()
                Text(session.createdAt, style: .date)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                ForEach(session.sensorsEnabled) { SensorBadgeView(sensor: $0) }
            }
            Text("Duration: \(Int(session.duration))s")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
