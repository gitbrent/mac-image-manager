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

#Preview("Empty State") {
    PaneImageViewer(selectedImage: nil)
        .frame(width: 300, height: 400)
}

#Preview("With Image") {
    PaneImageViewer(
        selectedImage: Bundle.main.resourceURL?.appendingPathComponent("preview1.png")
    )
    .frame(width: 300, height: 400)
}
