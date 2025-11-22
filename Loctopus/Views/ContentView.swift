import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appModel: AppViewModel
    @EnvironmentObject var recordingModel: RecordingViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .regular {
            NavigationSplitView {
                List {
                    NavigationLink("Instruments", destination: InstrumentsView(appModel: appModel))
                    NavigationLink("Sessions", destination: SessionsListView(appModel: appModel))
                    NavigationLink("Settings", destination: SettingsView(appModel: appModel))
                }
                .navigationTitle("Loctopus")
            } detail: {
                InstrumentsView(appModel: appModel)
            }
        } else {
            TabView {
                NavigationStack { InstrumentsView(appModel: appModel) }
                    .tabItem { Label("Instruments", systemImage: "dot.radiowaves.left.and.right") }
                NavigationStack { SessionsListView(appModel: appModel) }
                    .tabItem { Label("Sessions", systemImage: "clock.fill") }
                NavigationStack { SettingsView(appModel: appModel) }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
        }
    }
}
