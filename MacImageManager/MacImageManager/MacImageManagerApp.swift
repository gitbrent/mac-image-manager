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
                Toggle("Show Detailed Metrics", isOn: Binding(
                    get: { browserModel.showDetailedMetrics },
                    set: { _ in browserModel.toggleMetricsDisplay() }
                ))
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Divider()

                // Zoom options
                Toggle("Actual Size", isOn: Binding(
                    get: { browserModel.zoomLevel == .actual },
                    set: { _ in browserModel.setZoomLevel(.actual) }
                ))
                .keyboardShortcut("0", modifiers: .command)

                Button("Zoom In") {
                    browserModel.setZoomLevel(.zoomIn)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    browserModel.setZoomLevel(.zoomOut)
                }
                .keyboardShortcut("-", modifiers: .command)

                Toggle("Zoom to Fit", isOn: Binding(
                    get: { browserModel.zoomLevel == .fit },
                    set: { _ in browserModel.setZoomLevel(.fit) }
                ))
                .keyboardShortcut("/", modifiers: .command)

                Divider()

                Toggle("Sort by Name", isOn: Binding(
                    get: { browserModel.sortBy == .name },
                    set: { _ in browserModel.setSortCriteria(.name) }
                ))
                .keyboardShortcut("1", modifiers: .command)

                Toggle("Sort by Size", isOn: Binding(
                    get: { browserModel.sortBy == .size },
                    set: { _ in browserModel.setSortCriteria(.size) }
                ))
                .keyboardShortcut("2", modifiers: .command)

                Toggle("Sort by Date", isOn: Binding(
                    get: { browserModel.sortBy == .date },
                    set: { _ in browserModel.setSortCriteria(.date) }
                ))
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Toggle("Ascending", isOn: Binding(
                    get: { browserModel.sortAscending },
                    set: { _ in browserModel.toggleSortDirection() }
                ))
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Toggle("Descending", isOn: Binding(
                    get: { !browserModel.sortAscending },
                    set: { _ in browserModel.toggleSortDirection() }
                ))
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Divider()
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
