//
//  PaneVideoViewer.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/28/25.
//

import SwiftUI
import AVKit
import Combine

struct PaneVideoViewer: View {
    let videoUrl: URL?
    @EnvironmentObject private var browserModel: BrowserModel
    @State private var player: AVPlayer?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        Group {
            if videoUrl != nil {
                // Video Player with built-in controls
                GeometryReader { geometry in
                    Group {
                        if let scale = browserModel.zoomLevel.scale {
                            // Fixed scale (Actual Size or 50%)
                            ScrollView([.horizontal, .vertical]) {
                                VideoPlayer(player: player)
                                    .frame(
                                        width: geometry.size.width * scale,
                                        height: geometry.size.height * scale
                                    )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                        } else {
                            // Zoom to Fit
                            VideoPlayer(player: player)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(16)
                        }
                    }
                }
            } else {
                // Empty State
                VStack {
                    Image(systemName: "film")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("(select a video file)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //.background(Color(NSColor.windowBackgroundColor))
        .background(Color(NSColor.black))
        .onChange(of: videoUrl) { oldValue, newValue in
            loadVideo(from: newValue)
        }
        .onAppear {
            loadVideo(from: videoUrl)
            setupVideoActionSubscription()
        }
        .onDisappear {
            cleanup()
        }
    }

    private func loadVideo(from url: URL?) {
        cleanup()

        guard let url = url else { return }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)

        self.player = newPlayer

        // Update the browser model with the current player reference
        browserModel.setVideoPlayer(newPlayer)
    }

    private func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()

        // Clear the browser model's player reference
        browserModel.setVideoPlayer(nil)
    }

    private func setupVideoActionSubscription() {
        browserModel.videoActionPublisher
            .sink { [weak browserModel] action in
                guard let player = browserModel?.currentVideoPlayer else { return }
                handleVideoAction(action, for: player)
            }
            .store(in: &cancellables)
    }

    private func handleVideoAction(_ action: BrowserModel.VideoAction, for player: AVPlayer) {
        switch action {
        case .play:
            player.play()

        case .pause:
            player.pause()

        case .toggle:
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                player.play()
            }

        case .jumpForward:
            let currentTime = player.currentTime()
            let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
            player.seek(to: newTime)

        case .jumpBackward:
            let currentTime = player.currentTime()
            let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
            let startTime = CMTime.zero
            player.seek(to: CMTimeMaximum(newTime, startTime))

        case .restart:
            player.seek(to: CMTime.zero)
            player.play()
        }
    }


}

#Preview("No Selection") {
    PaneVideoViewer(videoUrl: nil)
        .frame(width: 300, height: 400)
}

#Preview("Video Selected") {
    PaneVideoViewer(
        videoUrl: URL(fileURLWithPath: "/tmp/sample.mp4")
    )
    .frame(width: 500, height: 400)
}
