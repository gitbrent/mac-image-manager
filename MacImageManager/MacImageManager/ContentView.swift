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
    @State private var selectedImage: URL?

    var body: some View {
        HSplitView {
            // Left sidebar - File browser
            PaneFileBrowserView(selectedImage: $selectedImage)
                .frame(minWidth: 200, maxWidth: 400)

            // Right pane - Image viewer
            PaneImageViewer(selectedImage: selectedImage)
                .frame(minWidth: 400)
        }
        .fileImporter(
            isPresented: $browserModel.showingFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                let url = try result.get()
                if url.count > 0 {
                    browserModel.navigateInto(directory: url[0])
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
        .frame(width: 600, height: 400)
}
