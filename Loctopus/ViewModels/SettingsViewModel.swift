import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isCloudEnabled: Bool
    @Published var useMetric: Bool = true
    @Published var mapStyle: Int = 0
    @Published var defaultSampleRate: Double = 30

    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
        self.isCloudEnabled = appModel.cloudEnabled
    }

    func toggleCloud() {
        appModel.toggleCloud(isCloudEnabled)
    }
}
