import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppViewModel
    @StateObject private var viewModel: SettingsViewModel

    init(appModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appModel: appModel))
    }

    var body: some View {
        Form {
            Section("Storage & Sync") {
                Toggle(isOn: $viewModel.isCloudEnabled) {
                    Text("Sync with iCloud")
                }
                Button("Sync now") {
                    Task { viewModel.toggleCloud() }
                }
                Text(appModel.cloudEnabled ? "Using iCloud Private Database" : "Local-only storage")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Units & Display") {
                Picker("Units", selection: $viewModel.useMetric) {
                    Text("Metric").tag(true)
                    Text("Imperial").tag(false)
                }.pickerStyle(.segmented)
                Picker("Map Style", selection: $viewModel.mapStyle) {
                    Text("Standard").tag(0)
                    Text("Satellite").tag(1)
                    Text("Hybrid").tag(2)
                }
            }
            Section("Privacy") {
                Text("Loctopus does not collect analytics, does not include ads, and only communicates with Apple's iCloud when you enable sync.")
            }
            Section("About") {
                Text("Loctopus")
                Text("Version 1.0")
                    .foregroundStyle(.secondary)
                Text("Privacy-first sensor lab for iPhone and iPad.")
            }
        }
        .navigationTitle("Settings")
    }
}
