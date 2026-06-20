import SwiftUI

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
            CommandGroup(replacing: .newItem) { }   // hide "New Window" menu item
        }
    }
}
