import SwiftUI

@main
struct LoctopusApp: App {
    @StateObject private var appModel: AppViewModel
    @StateObject private var recordingModel: RecordingViewModel

    init() {
        let appModel = AppViewModel()
        _appModel = StateObject(wrappedValue: appModel)
        _recordingModel = StateObject(wrappedValue: RecordingViewModel(appModel: appModel))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .environmentObject(recordingModel)
        }
    }
}
