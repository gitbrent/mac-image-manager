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
                // Add the shared model to the environment so child views can access it
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

            // Remove the (⌘W) "Close" item from `File`
            CommandGroup(replacing: .saveItem) {}

            // File operations
            CommandGroup(after: .newItem) {
                Button("Open Folder...") {
                    browserModel.showingFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Go Up One Level") {
                    browserModel.navigateUp()
                }
                .keyboardShortcut(.upArrow, modifiers: .command)
                .disabled(!browserModel.canNavigateUp)

                Button("Search") {
                    browserModel.focusSearchField()
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Rename File") {
                    browserModel.startRenamingSelectedFile()
                }
                .keyboardShortcut(.return, modifiers: [])
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

            // Add sorting commands to existing View menu
            CommandGroup(after: .toolbar) {
                Button("Sort by Name") {
                    browserModel.setSortCriteria(.name)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Sort by Size") {
                    browserModel.setSortCriteria(.size)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Sort by Date") {
                    browserModel.setSortCriteria(.date)
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button("Toggle Sort Direction") {
                    browserModel.toggleSortDirection()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            // Playback menu for video and GIF controls
            CommandMenu("Playback") {
                // Common control
                Button("Play/Pause") {
                    if browserModel.selectedFileIsVideo {
                        browserModel.toggleVideoPlayback()
                    } else if browserModel.selectedFileIsGif {
                        browserModel.toggleGifPlayback()
                    }
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(!browserModel.selectedFileIsVideo && !browserModel.selectedFileIsGif)

                Divider()

                // Video-specific controls
                if browserModel.selectedFileIsVideo {
                    Button("Jump Backward 10s") {
                        browserModel.jumpVideoBackward()
                    }
                    .keyboardShortcut(.leftArrow, modifiers: .command)

                    Button("Jump Forward 10s") {
                        browserModel.jumpVideoForward()
                    }
                    .keyboardShortcut(.rightArrow, modifiers: .command)

                    Divider()

                    Button("Restart Video") {
                        browserModel.restartVideo()
                    }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                }

                // GIF-specific controls
                if browserModel.selectedFileIsGif {
                    Button("Previous Frame") {
                        browserModel.previousGifFrame()
                    }
                    .keyboardShortcut(.leftArrow, modifiers: .command)

                    Button("Next Frame") {
                        browserModel.nextGifFrame()
                    }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                }
            }
        }
    }
}
