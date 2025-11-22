import SwiftUI
import MapKit

struct SessionDetailView: View {
    @EnvironmentObject var appModel: AppViewModel
    @State var session: Session
    @State private var exportURL: URL?

    init(session: Session) {
        _session = State(initialValue: session)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Name", text: $session.name)
                    .font(.title2)
                Text("\(session.createdAt.formatted()) • Duration: \(Int(session.duration))s")
                    .foregroundStyle(.secondary)
                TagsView(tags: $session.tags)
                TextField("Notes", text: Binding($session.notes, replacingNilWith: ""), axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .textFieldStyle(.roundedBorder)
                sensorCards
                exportSection
            }
            .padding()
        }
        .navigationTitle(session.name)
        .toolbar { Button("Save") { Task { try? await appModel.sessionStore.updateSession(session) } } }
        .sheet(item: $exportURL) { url in ShareView(url: url) }
    }

    private var sensorCards: some View {
        VStack(spacing: 12) {
            if session.sensorsEnabled.contains(.gps) {
                SensorSection(title: "GPS") {
                    if let sample = try? appModel.sessionStore.loadSamples(for: session, sensor: .gps, as: GPSSample.self).last {
                        Map(initialPosition: .region(.init(center: CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            if session.sensorsEnabled.contains(.accelerometer) {
                SensorSection(title: "Accelerometer") {
                    if let sample = try? appModel.sessionStore.loadSamples(for: session, sensor: .accelerometer, as: MotionSample.self).last {
                        StatRow(title: "Last", value: String(format: "x %.2f y %.2f z %.2f", sample.x, sample.y, sample.z))
                    }
                }
            }
            if session.sensorsEnabled.contains(.gyroscope) {
                SensorSection(title: "Gyroscope") {
                    if let sample = try? appModel.sessionStore.loadSamples(for: session, sensor: .gyroscope, as: MotionSample.self).last {
                        StatRow(title: "Last", value: String(format: "x %.2f y %.2f z %.2f", sample.x, sample.y, sample.z))
                    }
                }
            }
            if session.sensorsEnabled.contains(.magnetometer) {
                SensorSection(title: "Magnetometer") {
                    if let sample = try? appModel.sessionStore.loadSamples(for: session, sensor: .magnetometer, as: MotionSample.self).last {
                        StatRow(title: "Field", value: String(format: "x %.1f y %.1f z %.1f", sample.x, sample.y, sample.z))
                    }
                }
            }
            if session.sensorsEnabled.contains(.barometer) {
                SensorSection(title: "Barometer") {
                    if let sample = try? appModel.sessionStore.loadSamples(for: session, sensor: .barometer, as: BarometerSample.self).last {
                        StatRow(title: "Pressure", value: String(format: "%.2f kPa", sample.pressure))
                    }
                }
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export")
                .font(.headline)
            HStack {
                Button("GPX") { Task { exportURL = try? await appModel.exportService.exportGPX(session: session, store: appModel.sessionStore) } }
                Button("CSV") { Task { exportURL = try? await appModel.exportService.exportCSV(session: session, store: appModel.sessionStore) } }
                Button("JSON") { Task { exportURL = try? await appModel.exportService.exportJSON(session: session, store: appModel.sessionStore) } }
                Button("ZIP") { Task { exportURL = try? await appModel.exportService.exportZIP(session: session, store: appModel.sessionStore) } }
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct SensorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct TagsView: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""
    var body: some View {
        VStack(alignment: .leading) {
            Text("Tags")
                .font(.headline)
            HStack {
                TextField("Add tag", text: $newTag)
                Button("Add") {
                    guard !newTag.isEmpty else { return }
                    tags.append(newTag)
                    newTag = ""
                }
            }
            HStack { ForEach(tags, id: \.self) { tag in Label(tag, systemImage: "tag") } }
        }
    }
}

extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(get: { source.wrappedValue ?? defaultValue }, set: { source.wrappedValue = $0 })
    }
}

private struct ShareView: View, Identifiable {
    let url: URL
    var id: URL { url }
    var body: some View { ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") } }
}
