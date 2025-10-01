//
//  PaneImageViewer.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/23/25.
//

import SwiftUI

struct PaneImageViewer: View {
    let selectedImage: URL?
    @State private var loadedImage: NSImage?
    @State private var currentLoadingURL: URL?
    @State private var loadingTask: Task<Void, Never>?

    var body: some View {
        Group {
            if selectedImage != nil {
                if let loadedImage = loadedImage, currentLoadingURL == selectedImage {
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
                        .padding(5)
                    Text("(select an image)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .onChange(of: selectedImage) { _, newValue in
            loadImage(from: newValue)
        }
        .onAppear {
            loadImage(from: selectedImage)
        }
    }

    private func loadImage(from url: URL?) {
        // Cancel any existing loading task
        loadingTask?.cancel()

        guard let url = url else {
            loadedImage = nil
            currentLoadingURL = nil
            return
        }

        // Don't reload if it's the exact same URL and we already have the image loaded for it
        if currentLoadingURL == url && loadedImage != nil {
            return
        }

        // Set the new loading URL and clear image if switching URLs
        let previousURL = currentLoadingURL
        currentLoadingURL = url

        // Clear the loaded image if we're switching to a different URL
        if previousURL != url {
            loadedImage = nil
        }

        loadingTask = Task {
            let image = await withTaskCancellationHandler {
                return await Task.detached(priority: .userInitiated) {
                    NSImage(contentsOf: url)
                }.value
            } onCancel: {
                // Handle cancellation if needed
            }

            // Only update if this task wasn't cancelled and we're still loading the same URL
            if !Task.isCancelled && currentLoadingURL == url {
                await MainActor.run {
                    self.loadedImage = image
                }
            }
        }
    }
}

#Preview("No Selection") {
    PaneImageViewer(selectedImage: nil)
        .frame(width: 300, height: 400)
}

#Preview("Image Selected") {
    PaneImageViewer(
        selectedImage: URL(fileURLWithPath: "/tmp/image1.png")
    )
    .frame(width: 300, height: 400)
}
