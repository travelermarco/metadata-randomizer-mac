import SwiftUI

enum AppVersion {
    // Single source of truth — also written to Info.plist by build.sh
    static let current = "1.3"
}

@main
struct MetadataRandomizerApp: App {
    var body: some Scene {
        WindowGroup("Metadata Randomizer") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    NotificationCenter.default.post(name: .checkForUpdates, object: nil)
                }
            }
        }
    }
}

extension Notification.Name {
    static let checkForUpdates = Notification.Name("com.metarandom.mac.checkForUpdates")
}
