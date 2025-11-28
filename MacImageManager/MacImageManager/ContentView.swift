//
//  ContentView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // Use EnvironmentObject to access the shared model
    @EnvironmentObject private var browserModel: BrowserModel
    @FocusState private var activePane: ActivePane?

    enum ActivePane {
        case browser, viewer
    }

    // View selection based on media type
    @ViewBuilder
    private var mediaViewer: some View {
        if let file = browserModel.selectedFile {
            switch file.mediaType {
            case .staticImage, .unknown:
                PaneImageViewer(selectedImage: file.url)
                    .frame(minWidth: 250, maxWidth: .infinity)
            case .animatedGif:
                PaneGifViewer(gifUrl: file.url)
                    .frame(minWidth: 250, maxWidth: .infinity)
            case .video:
                PaneVideoViewer(videoUrl: file.url)
                    .frame(minWidth: 250, maxWidth: .infinity)
            case .directory:
                // Show placeholder for unsupported types
                VStack {
                    Image(systemName: "questionmark.square")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Unsupported file type")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        } else {
            // Empty state when no file is selected
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 8) {
                    Text("(select a file)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Choose an image or video from the browser to view it here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar (Left Pane)
            PaneFileBrowserView(selectedImage: $browserModel.selectedFile)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 500)
                .focused($activePane, equals: .browser)
        } detail: {
            // MARK: - Detail (Right Pane)
            mediaViewer
                .focused($activePane, equals: .viewer)
        }
        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(
            isPresented: $browserModel.showingFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let folderUrl = urls.first {
                    Task {
                        let folderItem = await FileItem(
                            url: folderUrl,
                            name: folderUrl.lastPathComponent,
                            isDirectory: true,
                            fileSize: 0,
                            modificationDate: Date(),
                            uti: .folder
                        )
                        browserModel.navigateInto(item: folderItem)
                    }
                }
            case .failure(let error):
                print("Failed to import folder: \(error.localizedDescription)")
            }
        }
        .onAppear {
            Task {
                await browserModel.loadInitialDirectory()
            }
        }
        .onChange(of: browserModel.currentDirectory) { _, _ in
            // Clear the selected image when navigating to a different directory
            browserModel.selectedFile = nil
        }
        .onKeyPress(.space) {
            if browserModel.selectedFileIsVideo {
                browserModel.toggleVideoPlayback()
                return .handled
            } else if browserModel.selectedFileIsGif {
                browserModel.toggleGifPlayback()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(phases: .down) { keyPress in
            if keyPress.characters == "r" && keyPress.modifiers.contains(.command) {
                if browserModel.canRenameSelectedFile {
                    browserModel.startRenamingSelectedFile()
                    return .handled
                }
            }
            return .ignored
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BrowserModel.preview)
        .frame(width: 500, height: 500)
}
