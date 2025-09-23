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
    @EnvironmentObject private var browserModel: DirectoryBrowserModel
    @State private var selectedImage: URL?

    var body: some View {
        HSplitView {
            // Left sidebar - File browser
            DirectoryBrowserView(selectedImage: $selectedImage)
                .frame(minWidth: 200, maxWidth: 400)
            
            // Right pane - Image viewer
            ImageViewerPane(selectedImage: selectedImage)
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

// Separate struct for the preview, as dev sandbox cant read `/Documents` etc.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DirectoryBrowserModel.forPreview())
            .frame(width: 800, height: 600)
    }
}

struct ImageViewerPane: View {
    let selectedImage: URL?
    @State private var loadedImage: NSImage?
    
    var body: some View {
        Group {
            if selectedImage != nil {
                if let loadedImage = loadedImage {
                    ScrollView([.horizontal, .vertical]) {
                        Image(nsImage: loadedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit) // These 2 lines: fit image to view
                            .containerRelativeFrame([.horizontal, .vertical]) // These 2 lines: fit image to view
                    }
                    .background(Color.black)
                } else {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                }
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select an image to view")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            loadImage(from: newValue)
        }
    }
    
    private func loadImage(from url: URL?) {
        guard let url = url else {
            loadedImage = nil
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self.loadedImage = image
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DirectoryBrowserModel.forPreview())
        .frame(width: 800, height: 600)
}
