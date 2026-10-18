import SwiftUI

@main
struct LifeUnlockedApp: App {
    @StateObject private var store = LifeStore()
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, (AppLanguage(rawValue: appLanguage) ?? .system).locale)
                .id(appLanguage)
        }
    }
}
