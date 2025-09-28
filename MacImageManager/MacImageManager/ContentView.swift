//
//  ContentView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // 1. Use EnvironmentObject to access the shared model
    @EnvironmentObject private var browserModel: BrowserModel
    @State private var selectedImage: FileItem?

    var body: some View {
        HSplitView {
            // Left pane - File browser
            PaneFileBrowserView(selectedImage: $selectedImage)
                .frame(minWidth: 250, maxWidth: 400)

            // Right pane - Image viewer
            PaneImageViewer(selectedImage: selectedImage?.url)
                //.frame(minWidth: 500) // needed?
        }
        .fileImporter(
            isPresented: $browserModel.showingFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                let urls = try result.get()
                if urls.count > 0 {
                    // Create a temporary FileItem for the imported folder
                    let folderUrl = urls[0]
                    let folderItem = FileItem(
                        url: folderUrl,
                        name: folderUrl.lastPathComponent,
                        iconName: "folder.fill",
                        isDirectory: true,
                        fileSize: 0,
                        modificationDate: Date(),
                        uti: .folder
                    )
                    browserModel.navigateInto(item: folderItem)
                }
            } catch {
                print("Failed to import folder: \(error.localizedDescription)")
            }
        }
        .onAppear {
            browserModel.loadInitialDirectory()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BrowserModel.preview)
        .frame(width: 600, height: 500)
}
