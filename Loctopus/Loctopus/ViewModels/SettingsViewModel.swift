import Foundation
import SwiftUI

enum StorageMode: String, CaseIterable {
    case localOnly = "Local Only"
    case iCloud = "Local + iCloud"
}

enum Units: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
}

enum MapStyle: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var storageManager = StorageManager.shared
    @Published var cloudKitManager = CloudKitManager.shared

    @Published var storageMode: StorageMode {
        didSet {
            UserDefaults.standard.set(storageMode.rawValue, forKey: "storageMode")
            updateStorageMode()
        }
    }

    @Published var units: Units {
        didSet {
            UserDefaults.standard.set(units.rawValue, forKey: "units")
        }
    }

    @Published var mapStyle: MapStyle {
        didSet {
            UserDefaults.standard.set(mapStyle.rawValue, forKey: "mapStyle")
        }
    }

    @Published var isSyncing = false

    init() {
        if let storageModeString = UserDefaults.standard.string(forKey: "storageMode"),
           let mode = StorageMode(rawValue: storageModeString) {
            storageMode = mode
        } else {
            storageMode = .localOnly
        }

        if let unitsString = UserDefaults.standard.string(forKey: "units"),
           let savedUnits = Units(rawValue: unitsString) {
            units = savedUnits
        } else {
            units = .metric
        }

        if let mapStyleString = UserDefaults.standard.string(forKey: "mapStyle"),
           let savedMapStyle = MapStyle(rawValue: mapStyleString) {
            mapStyle = savedMapStyle
        } else {
            mapStyle = .standard
        }
    }

    private func updateStorageMode() {
        switch storageMode {
        case .localOnly:
            cloudKitManager.disableSync()
        case .iCloud:
            cloudKitManager.enableSync()
        }
    }

    func syncNow() {
        Task {
            isSyncing = true
            await cloudKitManager.syncAllSessions()
            isSyncing = false
        }
    }

    var localStorageSize: String {
        storageManager.getFormattedStorageSize()
    }

    var iCloudStorageSize: String {
        "~"
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
