import SwiftUI
import ComposableArchitecture

@main
struct AppframeApp: App {
    static let store = Store(initialState: StatisticsFeature.State()) {
        StatisticsFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            StatisticsView(store: AppframeApp.store)
        }
    }
}
