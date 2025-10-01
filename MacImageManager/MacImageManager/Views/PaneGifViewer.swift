//
//  PaneGifViewer.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/28/25.
//

import SwiftUI
import WebKit
import ImageIO
import Combine

// MARK: - GIF Frame Data
struct GifFrame {
    let image: NSImage
    let delay: TimeInterval
}

// MARK: - GIF Loader
@MainActor
class GifLoader: ObservableObject {
    @Published var frames: [GifFrame] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var loadTask: Task<Void, Never>?
    private let maxFrameCache = 100 // Limit frames for very large GIFs

    init() {
        // Explicit initializer for the class
    }

    func load(from url: URL) {
        // Cancel any existing load task
        loadTask?.cancel()

        // Reset state
        frames = []
        error = nil
        isLoading = true

        loadTask = Task {
            do {
                let loadedFrames = try await loadGifFrames(from: url)

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                self.frames = loadedFrames
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
                self.isLoading = false
            }
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }

    private func loadGifFrames(from url: URL) async throws -> [GifFrame] {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    guard let data = try? Data(contentsOf: url),
                          let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
                        throw GifError.invalidFile
                    }

                    let frameCount = CGImageSourceGetCount(imageSource)
                    guard frameCount > 0 else {
                        throw GifError.noFrames
                    }

                    var frames: [GifFrame] = []

                    // For very large GIFs, limit the number of frames to prevent memory issues
                    let actualFrameCount = min(frameCount, self.maxFrameCache)

                    for index in 0..<actualFrameCount {
                        // Check for cancellation
                        if Task.isCancelled { return }

                        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
                            continue
                        }

                        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                        let delay = GifLoader.getFrameDelay(from: imageSource, at: index)

                        frames.append(GifFrame(image: nsImage, delay: delay))
                    }

                    continuation.resume(returning: frames)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    nonisolated private static func getFrameDelay(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return 0.1 // Default 100ms delay
        }

        // Try unclampedDelayTime first (more accurate), then delayTime
        let delayTime = (gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber)?.doubleValue
                    ?? (gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber)?.doubleValue
                    ?? 0.1

        // Ensure minimum delay of 10ms to prevent excessively fast animations
        return max(delayTime, 0.01)
    }
}

// MARK: - GIF Errors
enum GifError: Error, LocalizedError {
    case invalidFile
    case noFrames

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "Invalid GIF file"
        case .noFrames:
            return "GIF contains no frames"
        }
    }
}

// MARK: - WebView GIF Viewer (Fallback)
struct WebViewGifViewer: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

// MARK: - Main GIF Viewer
struct PaneGifViewer: View {
    let gifUrl: URL?

    @StateObject private var gifLoader = GifLoader()
    @State private var currentFrameIndex: Int = 0
    @State private var isPlaying: Bool = true
    @State private var animationSpeed: Double = 1.0
    @State private var timer: Timer?
    @State private var useWebView: Bool = false
    @State private var currentLoadingURL: URL?

    var body: some View {
        Group {
            if let gifUrl = gifUrl {
                VStack {
                    // Main Display Area
                    if useWebView {
                        // WebView fallback for complex GIFs
                        WebViewGifViewer(url: gifUrl)
                            .background(Color.black)
                    } else if gifLoader.isLoading {
                        ProgressView("Loading GIF...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    } else if let error = gifLoader.error {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text("Error loading GIF")
                                .font(.headline)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Try WebView") {
                                useWebView = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else if !gifLoader.frames.isEmpty {
                        // Custom frame-by-frame viewer
                        ScrollView([.horizontal, .vertical]) {
                            Image(nsImage: currentFrame)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .containerRelativeFrame([.horizontal, .vertical])
                        }
                        .background(Color.black)
                    } else {
                        // Empty frames
                        VStack {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text("No frames found")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    }

                    // Controls (only show for custom viewer)
                    if !useWebView && !gifLoader.frames.isEmpty {
                        VStack(spacing: 8) {
                            // Primary Controls
                            HStack {
                                // Play/Pause Button
                                Button(action: togglePlayPause) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)

                                // Previous Frame
                                Button(action: previousFrame) {
                                    Image(systemName: "backward.frame.fill")
                                        .font(.title2)
                                        .foregroundColor(isPlaying ? .gray : .white)
                                }
                                .buttonStyle(.plain)
                                .disabled(isPlaying)

                                // Next Frame
                                Button(action: nextFrame) {
                                    Image(systemName: "forward.frame.fill")
                                        .font(.title2)
                                        .foregroundColor(isPlaying ? .gray : .white)
                                }
                                .buttonStyle(.plain)
                                .disabled(isPlaying)

                                Spacer()

                                // WebView Toggle
                                Button("WebView") {
                                    stopAnimation()
                                    useWebView = true
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.white)
                            }

                            // Speed Control
                            HStack {
                                Text("Speed")
                                    .foregroundColor(.white)
                                Slider(value: $animationSpeed, in: 0.25...3.0, step: 0.25)
                                    .frame(maxWidth: 150)
                                Text(String(format: "%.2fx", animationSpeed))
                                    .foregroundColor(.white)
                                    .frame(width: 50, alignment: .leading)
                            }

                            // Frame Info
                            if !gifLoader.frames.isEmpty {
                                Text("Frame \(currentFrameIndex + 1) / \(gifLoader.frames.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                    }
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
        .onChange(of: gifUrl) { _, newValue in
            loadGif(from: newValue)
        }
        .onChange(of: animationSpeed) { _, _ in
            if isPlaying {
                restartAnimation()
            }
        }
        .onAppear {
            loadGif(from: gifUrl)
        }
        .onDisappear {
            stopAnimation()
            gifLoader.cancel()
        }
    }

    // MARK: - Computed Properties
    private var currentFrame: NSImage {
        guard !gifLoader.frames.isEmpty,
              currentFrameIndex < gifLoader.frames.count else {
            // Return a placeholder image if no frames available
            return NSImage(systemSymbolName: "photo", accessibilityDescription: nil) ?? NSImage()
        }
        return gifLoader.frames[currentFrameIndex].image
    }

    // MARK: - Methods
    private func loadGif(from url: URL?) {
        stopAnimation()
        currentFrameIndex = 0
        useWebView = false
        currentLoadingURL = url

        guard let url = url else {
            gifLoader.cancel()
            return
        }

        // Only load if URL changed
        if currentLoadingURL == url {
            gifLoader.load(from: url)

            // Start animation when frames are loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !gifLoader.frames.isEmpty && isPlaying {
                    startAnimation()
                }
            }
        }
    }

    private func startAnimation() {
        guard !gifLoader.frames.isEmpty else { return }

        stopAnimation()

        // Use the actual frame delay from the GIF, adjusted by speed
        let currentDelay = gifLoader.frames[currentFrameIndex].delay / animationSpeed

        timer = Timer.scheduledTimer(withTimeInterval: currentDelay, repeats: false) { _ in
            nextFrame()
            if isPlaying {
                startAnimation() // Schedule next frame
            }
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    private func restartAnimation() {
        stopAnimation()
        if isPlaying && !gifLoader.frames.isEmpty {
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
        guard !gifLoader.frames.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex + 1) % gifLoader.frames.count
    }

    private func previousFrame() {
        guard !gifLoader.frames.isEmpty else { return }
        currentFrameIndex = currentFrameIndex > 0 ? currentFrameIndex - 1 : gifLoader.frames.count - 1
    }
}

// MARK: - Previews
#Preview("No Selection") {
    PaneGifViewer(gifUrl: nil)
        .frame(width: 400, height: 500)
}

#Preview("GIF Selected") {
    PaneGifViewer(
        gifUrl: URL(fileURLWithPath: "/tmp/animation.gif")
    )
    .frame(width: 400, height: 500)
}
