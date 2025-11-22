import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var syncingWithCloud = false
    @Published var cloudEnabled = false

    let sessionStore = SessionStore()
    let locationService = LocationService()
    let motionService = MotionService()
    let barometerService = BarometerService()
    let cloudSync = CloudSyncService()
    let exportService = ExportService()

    func refreshSessions() async {
        sessions = await sessionStore.allSessions()
    }

    func toggleCloud(_ enabled: Bool) {
        cloudEnabled = enabled
    }
}
