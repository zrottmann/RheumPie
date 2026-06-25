import SwiftUI

@main
struct RheumPieApp: App {
    @State private var store = ArticleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { store.load() }
        }
    }
}
