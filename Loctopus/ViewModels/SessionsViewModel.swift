import Foundation

@MainActor
final class SessionsViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var searchText: String = ""
    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
    }

    func load() async {
        sessions = await appModel.sessionStore.allSessions()
    }

    func delete(_ session: Session) async {
        try? await appModel.sessionStore.deleteSession(session)
        sessions = await appModel.sessionStore.allSessions()
    }

    var filteredSessions: [Session] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) }
    }
}
