import Foundation
import SwiftUI

@MainActor
class SessionListViewModel: ObservableObject {
    @Published var storageManager = StorageManager.shared
    @Published var cloudKitManager = CloudKitManager.shared

    @Published var searchText = ""
    @Published var isRefreshing = false

    var filteredSessions: [Session] {
        if searchText.isEmpty {
            return storageManager.sessions
        } else {
            return storageManager.sessions.filter { session in
                session.name.localizedCaseInsensitiveContains(searchText) ||
                session.notes.localizedCaseInsensitiveContains(searchText) ||
                session.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    func deleteSession(_ session: Session) {
        Task {
            if cloudKitManager.isSyncEnabled {
                await cloudKitManager.deleteSession(session)
            }
            storageManager.deleteSession(session)
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true

        if cloudKitManager.isSyncEnabled {
            await cloudKitManager.syncAllSessions()
        }

        isRefreshing = false
    }
}
