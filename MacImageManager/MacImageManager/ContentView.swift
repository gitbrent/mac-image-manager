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
    @State private var selectedFile: FileItem?

    // View selection based on media type
    @ViewBuilder
    private var mediaViewer: some View {
        if let file = selectedFile {
            switch file.mediaType {
            case .staticImage:
                PaneImageViewer(selectedImage: file.url)
                    .frame(minWidth: 250)
            case .animatedGif:
                PaneGifViewer(gifUrl: file.url)
                    .frame(minWidth: 250)
            case .video:
                PaneVideoViewer(videoUrl: file.url)
                    .frame(minWidth: 250)
            case .directory, .unknown:
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
            VStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("(select a file)")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    var body: some View {
        HSplitView {
            // Left pane - File browser
            PaneFileBrowserView(selectedImage: $selectedFile)
                .frame(minWidth: 250, maxWidth: 400)

            // Right pane - Media viewer
            mediaViewer
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
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BrowserModel.preview)
        .frame(width: 500, height: 500)
}
