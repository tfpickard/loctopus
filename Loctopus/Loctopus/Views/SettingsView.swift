import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                storageSection

                unitsSection

                privacySection

                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var storageSection: some View {
        Section("Storage & Sync") {
            Picker("Storage Mode", selection: $viewModel.storageMode) {
                ForEach(StorageMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("On Device")
                Spacer()
                Text(viewModel.localStorageSize)
                    .foregroundColor(.secondary)
            }

            if viewModel.storageMode == .iCloud {
                HStack {
                    Text("iCloud")
                    Spacer()
                    if viewModel.isSyncing {
                        ProgressView()
                    } else {
                        Text(viewModel.iCloudStorageSize)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    viewModel.syncNow()
                } label: {
                    HStack {
                        Text("Sync Now")
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                .disabled(viewModel.isSyncing)

                if let lastSync = viewModel.cloudKitManager.lastSyncDate {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var unitsSection: some View {
        Section("Units & Display") {
            Picker("Units", selection: $viewModel.units) {
                ForEach(Units.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }

            Picker("Map Style", selection: $viewModel.mapStyle) {
                ForEach(MapStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            VStack(alignment: .leading, spacing: 12) {
                privacyItem(
                    icon: "nosign",
                    title: "No Ads",
                    description: "Loctopus is completely ad-free"
                )

                privacyItem(
                    icon: "eye.slash",
                    title: "No Analytics",
                    description: "We don't collect any usage data or telemetry"
                )

                privacyItem(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "All data stays on your device or in your private iCloud"
                )

                privacyItem(
                    icon: "network.slash",
                    title: "No Third Parties",
                    description: "No SDKs, trackers, or external services"
                )
            }
            .padding(.vertical, 8)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(viewModel.buildNumber)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Loctopus")
                    .font(.headline)

                Text("A privacy-first sensor recording lab for iOS and iPadOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private func privacyItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
