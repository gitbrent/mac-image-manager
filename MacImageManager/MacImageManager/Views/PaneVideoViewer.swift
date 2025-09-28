//
//  PaneVideoViewer.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/28/25.
//

import SwiftUI
import AVKit

struct PaneVideoViewer: View {
    let videoUrl: URL?

    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var volume: Float = 1.0
    @State private var playbackRate: Float = 1.0

    // Time observer
    @State private var timeObserver: Any?

    var body: some View {
        Group {
            if let videoUrl = videoUrl {
                VStack {
                    // Video Player
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Custom Controls
                    VStack {
                        // Time Slider and Labels
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .monospacedDigit()

                            Slider(value: Binding(
                                get: { currentTime },
                                set: { seek(to: $0) }
                            ), in: 0...duration)

                            Text(formatTime(duration))
                                .font(.caption)
                                .monospacedDigit()
                        }

                        HStack {
                            // Play/Pause
                            Button(action: togglePlayPause) {
                                Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                                    .font(.title)
                            }

                            // Rewind 10s
                            Button(action: rewindTenSeconds) {
                                Image(systemName: "gobackward.10")
                                    .font(.title)
                            }

                            // Forward 10s
                            Button(action: forwardTenSeconds) {
                                Image(systemName: "goforward.10")
                                    .font(.title)
                            }

                            // Volume
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                Slider(value: $volume, in: 0...1) {
                                    Text("Volume")
                                }
                                .frame(width: 100)
                            }

                            // Playback Speed
                            Menu {
                                Button("0.5x") { setPlaybackRate(0.5) }
                                Button("1.0x") { setPlaybackRate(1.0) }
                                Button("1.5x") { setPlaybackRate(1.5) }
                                Button("2.0x") { setPlaybackRate(2.0) }
                            } label: {
                                Text("\(String(format: "%.1fx", playbackRate))")
                            }
                        }
                    }
                    .padding()
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
        .onChange(of: videoUrl) { oldValue, newValue in
            loadVideo(from: newValue)
        }
        .onChange(of: volume) { oldValue, newValue in
            player?.volume = volume
        }
        .onAppear {
            loadVideo(from: videoUrl)
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

        // Set initial volume
        newPlayer.volume = volume

        // Observe video duration
        let durationObserver = playerItem.observe(\.duration) { item, _ in
            duration = item.duration.seconds
        }

        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }

        self.player = newPlayer
    }

    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    private func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
    }

    private func seek(to time: Double) {
        let newTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: newTime)
    }

    private func rewindTenSeconds() {
        seek(to: max(currentTime - 10, 0))
    }

    private func forwardTenSeconds() {
        seek(to: min(currentTime + 10, duration))
    }

    private func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }

    private func formatTime(_ seconds: Double) -> String {
        let time = Int(seconds)
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
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
