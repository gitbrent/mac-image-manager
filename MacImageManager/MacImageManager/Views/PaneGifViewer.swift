//
//  PaneGifViewer.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/28/25.
//

import SwiftUI
import AVFoundation

struct PaneGifViewer: View {
    let gifUrl: URL?

    @State private var isPlaying: Bool = true
    @State private var currentFrame: NSImage?
    @State private var frameCount: Int = 0
    @State private var currentFrameIndex: Int = 0
    @State private var animationSpeed: Double = 1.0

    // Timer for controlling animation
    @State private var timer: Timer?
    // Image source for frame extraction
    private let imageSource: CGImageSource?

    init(gifUrl: URL?) {
        self.gifUrl = gifUrl

        // Initialize CGImageSource if URL is provided
        if let url = gifUrl {
            if let data = try? Data(contentsOf: url) {
                imageSource = CGImageSourceCreateWithData(data as CFData, nil)
            } else {
                imageSource = nil
            }
        } else {
            imageSource = nil
        }

        // Get frame count if available
        if let source = imageSource {
            frameCount = CGImageSourceGetCount(source)
        }
    }

    var body: some View {
        Group {
            if let gifUrl = gifUrl {
                VStack {
                    // GIF Display
                    if let currentFrame = currentFrame {
                        ScrollView([.horizontal, .vertical]) {
                            Image(nsImage: currentFrame)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .containerRelativeFrame([.horizontal, .vertical])
                        }
                    } else {
                        ProgressView("Loading GIF...")
                    }

                    // Controls
                    HStack {
                        // Play/Pause Button
                        Button(action: togglePlayPause) {
                            Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                                .font(.title)
                        }

                        // Previous Frame
                        Button(action: previousFrame) {
                            Image(systemName: "backward.frame")
                                .font(.title)
                        }
                        .disabled(isPlaying)

                        // Next Frame
                        Button(action: nextFrame) {
                            Image(systemName: "forward.frame")
                                .font(.title)
                        }
                        .disabled(isPlaying)

                        // Speed Control
                        Slider(value: $animationSpeed, in: 0.25...2.0, step: 0.25) {
                            Text("Speed")
                        }
                        Text(String(format: "%.2fx", animationSpeed))
                    }
                    .padding()
                }
                .background(Color.black)
            } else {
                // Empty State
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("(select an animated GIF)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .task(id: gifUrl) {
            loadGif(from: gifUrl)
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: animationSpeed) { oldValue, newValue in
            if isPlaying {
                restartAnimation()
            }
        }
    }

    private func loadGif(from url: URL?) {
        stopAnimation()
        currentFrame = nil

        guard let url = url else { return }

        // Load first frame immediately
        if let source = imageSource,
           let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            currentFrame = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

            if isPlaying {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        guard frameCount > 0 else { return }

        // Calculate delay based on speed
        let baseDelay = 0.1 // 10 frames per second base speed
        let adjustedDelay = baseDelay / animationSpeed

        timer = Timer.scheduledTimer(withTimeInterval: adjustedDelay, repeats: true) { _ in
            nextFrame()
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    private func restartAnimation() {
        stopAnimation()
        if isPlaying {
            startAnimation()
        }
    }

    private func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            startAnimation()
        } else {
            stopAnimation()
        }
    }

    private func nextFrame() {
        guard let source = imageSource else { return }

        currentFrameIndex = (currentFrameIndex + 1) % frameCount
        if let cgImage = CGImageSourceCreateImageAtIndex(source, currentFrameIndex, nil) {
            currentFrame = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
    }

    private func previousFrame() {
        guard let source = imageSource else { return }

        currentFrameIndex = currentFrameIndex > 0 ? currentFrameIndex - 1 : frameCount - 1
        if let cgImage = CGImageSourceCreateImageAtIndex(source, currentFrameIndex, nil) {
            currentFrame = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
    }
}

#Preview("No Selection") {
    PaneGifViewer(gifUrl: nil)
        .frame(width: 300, height: 400)
}

#Preview("GIF Selected") {
    PaneGifViewer(
        gifUrl: URL(fileURLWithPath: "/tmp/animation.gif")
    )
    .frame(width: 300, height: 400)
}
