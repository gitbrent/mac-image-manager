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
    @State private var isLoading: Bool = false
    @EnvironmentObject private var browserModel: BrowserModel

    var body: some View {
        Group {
            if selectedImage != nil {
                ZStack {
                    // Show the loaded image (either current or previous)
                    if let loadedImage = loadedImage {
                        ScrollView([.horizontal, .vertical]) {
                            Group {
                                if let scale = browserModel.zoomLevel.scale {
                                    // Fixed scale (Actual Size or 50%)
                                    Image(nsImage: loadedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaleEffect(scale)
                                } else {
                                    // Zoom to Fit
                                    Image(nsImage: loadedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .containerRelativeFrame([.horizontal, .vertical])
                                }
                            }
                        }
                        .background(Color.black)
                    } else {
                        // Only show black background with spinner if no image has been loaded yet
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    }

                    // Show loading indicator in corner when loading a new image but previous image exists
                    if isLoading && loadedImage != nil {
                        VStack {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding()
                            }
                            Spacer()
                        }
                    }
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
            isLoading = false
            return
        }

        // Don't reload if it's the exact same URL and we already have the image loaded for it
        if currentLoadingURL == url && loadedImage != nil {
            isLoading = false
            return
        }

        // Set the new loading URL but keep the previous image
        currentLoadingURL = url

        // Only clear the loaded image if we don't have any image yet
        if loadedImage == nil {
            isLoading = true
        } else {
            // We have a previous image, show loading indicator but keep the image
            isLoading = true
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
                    self.isLoading = false
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
