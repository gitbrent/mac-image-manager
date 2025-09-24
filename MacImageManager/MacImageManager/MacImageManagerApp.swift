//
//  MacImageManagerApp.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

@main
struct MacImageManagerApp: App {
    @StateObject private var browserModel = BrowserModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
                // 💡 Add the shared model to the environment so child views can access it
                .environmentObject(browserModel)
        }
        .windowResizability(.contentSize)
        .commands {
            // Add keyboard shortcuts
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(after: .newItem) {
                Button("Open Folder...") {
                    browserModel.showingFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
        }
    }
}
