import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad layout with sidebar
            NavigationSplitView {
                SidebarView()
            } detail: {
                InstrumentDashboardView()
            }
        } else {
            // iPhone layout with tabs
            TabView {
                InstrumentDashboardView()
                    .tabItem {
                        Label("Instruments", systemImage: "waveform.path.ecg")
                    }

                SessionListView()
                    .tabItem {
                        Label("Sessions", systemImage: "list.bullet")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
        }
    }
}

struct SidebarView: View {
    @State private var selection: SidebarItem? = .instruments

    enum SidebarItem: Hashable {
        case instruments
        case sessions
        case settings
    }

    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: SidebarItem.instruments) {
                Label("Instruments", systemImage: "waveform.path.ecg")
            }

            NavigationLink(value: SidebarItem.sessions) {
                Label("Sessions", systemImage: "list.bullet")
            }

            NavigationLink(value: SidebarItem.settings) {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .navigationTitle("Loctopus")
    }
}
