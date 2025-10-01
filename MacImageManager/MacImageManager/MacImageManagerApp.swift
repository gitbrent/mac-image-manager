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
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowResizability(.contentSize)
        .commands {
            // Hide the default Edit menu
            CommandGroup(replacing: .textEditing) {}
            
            // Hide the default View menu
            CommandGroup(replacing: .toolbar) {}
            
            // Replace the new item commands
            CommandGroup(replacing: .newItem) {}
            
            // File operations
            CommandGroup(after: .newItem) {
                Button("Open Folder...") {
                    browserModel.showingFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Rename File") {
                    browserModel.startRenamingSelectedFile()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!browserModel.canRenameSelectedFile)
                
                Button("Delete File") {
                    browserModel.deleteSelectedFile()
                }
                .keyboardShortcut(.delete)
                .disabled(!browserModel.hasSelectedFile)
                
                Divider()
                
                Button("Show in Finder") {
                    browserModel.showSelectedFileInFinder()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!browserModel.hasSelectedFile)
            }
            
            // Playback menu for video controls (inserted explicitly after our File operations)
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    browserModel.toggleVideoPlayback()
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(!browserModel.selectedFileIsVideo)
                
                Divider()
                
                Button("Jump Backward 10s") {
                    browserModel.jumpVideoBackward()
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .disabled(!browserModel.selectedFileIsVideo)
                
                Button("Jump Forward 10s") {
                    browserModel.jumpVideoForward()
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .disabled(!browserModel.selectedFileIsVideo)
                
                Divider()
                
                Button("Restart Video") {
                    browserModel.restartVideo()
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
                .disabled(!browserModel.selectedFileIsVideo)
            }
        }
    }
}
