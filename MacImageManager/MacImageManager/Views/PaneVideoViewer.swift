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

    var body: some View {
        Group {
            if videoUrl != nil {
                // Video Player with built-in controls
                VideoPlayer(player: player)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(16)
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
    }

    private func cleanup() {
        player?.pause()
        player = nil
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
