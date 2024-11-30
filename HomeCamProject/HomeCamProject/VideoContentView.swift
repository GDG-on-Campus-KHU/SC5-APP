//
//  VideoContentView.swift
//  HomeCamProject
//
//  Created by HanJW on 11/30/24.
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct VideoContentView: View {
    @State private var player: AVPlayer

    init() {
        let url = Bundle.main.url(forResource: "sample", withExtension: "mp4")!
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VStack {
            VideoPlayerView(player: player)
                .frame(height: 300)
                .onAppear {
                    player.play()
                }

            ControlView(player: player)
        }
    }
}

struct ControlView: View {
    @State private var isPlaying = false
    let player: AVPlayer

    var body: some View {
        HStack {
            Button(action: {
                if isPlaying {
                    player.pause()
                } else {
                    player.play()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause" : "play")
                    .resizable()
                    .frame(width: 25, height: 25)
            }
        }
    }
}

struct PlayerContentView: View {
    var body: some View {
        VideoContentView()
    }
}

#Preview {
    VideoContentView()
}
