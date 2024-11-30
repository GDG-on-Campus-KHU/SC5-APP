//
//  ConnectView.swift
//  HomeCamProject
//
//  Created by 박현빈 on 11/28/24.
//

import SwiftUI
import GRPC
import NIO
import Foundation
import PhotosUI
import AVFoundation
import Combine
import AVKit

// GRPC 채널 생성 예시

class VideoStreamService: ObservableObject {
    private var client: FDFireDetectionServiceNIOClient?
    private var streamCall: BidirectionalStreamingCall<FDVideoChunk, FDVideoResponse>?
    var player: AVPlayer?
    @Published var isPlaying = false
    @Published var fireDetected = false
    
    init() {
        setupGRPC()
    }
    
    private func setupGRPC() {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        let channel = try? GRPCChannelPool.with(
            target: .host("localhost", port: 50051),
            transportSecurity: .plaintext,
            eventLoopGroup: group
        )
        
        if let channel = channel {
            client = FDFireDetectionServiceNIOClient(channel: channel)
        }
    }
    
    func streamVideo(fileURL: URL) {
        print("begin")
        
        guard let client = client else {
            print("GRPC client not initialized")
            return
        }
        
        // 비디오 에셋 설정
        let asset = AVAsset(url: fileURL)
        
        // 플레이어 설정
        player = AVPlayer(url: fileURL)
        
        // 서버로부터의 응답을 처리할 스트림 콜 설정
        streamCall = client.streamVideo { response in
            DispatchQueue.main.async {
                if response.detected {
                    self.fireDetected = true
                    print("🔥 Fire detected at timestamp: \(response.timestamp)")
                } else {
                    self.fireDetected = false
                    print(". . . Streaming . . .")
                }
            }
        }
        
        // 비디오 프레임 추출 설정
        guard let reader = try? AVAssetReader(asset: asset),
              let videoTrack = asset.tracks(withMediaType: .video).first else { // 비디오 트랙을 가져오는 부분
            print("Failed to create asset reader")
            return
        }
        
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let readerOutput = AVAssetReaderTrackOutput(
             track: videoTrack,
             outputSettings: outputSettings
         )
         reader.add(readerOutput)
        
        // FPS 계산
        let fps = videoTrack.nominalFrameRate
        let frameDuration = 1.0 / Double(fps)
        
        // 프레임 전송 및 재생 시작
        reader.startReading()
        player?.play()
        isPlaying = true
        
        let startTime = Date()
        var frameCount = 0
        // 백그라운드 큐에서 프레임 처리
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // reader 상태 체크 추가
            guard reader.status == .reading else {
                print("Reader is not in reading state")
                self?.stopStreaming()
                return
            }
            
            while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                // reader 상태 지속적 체크
                if reader.status != .reading {
                    print("Reader status changed: \(reader.status)")
                    self?.stopStreaming()
                    break
                }
                
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    continue
                }
                
                // 타이밍 동기화
                let expectedTime = startTime.addingTimeInterval(Double(frameCount) * frameDuration)
                let delay = expectedTime.timeIntervalSinceNow
                if delay > 0 {
                    Thread.sleep(forTimeInterval: delay)
                }
                
                // JPEG 인코딩
                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                let context = CIContext()
                guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                      let jpegData = context.jpegRepresentation(
                        of: ciImage,
                        colorSpace: colorSpace,
                        options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7]
                      ) else { continue }
                
                // 프레임 전송
                let chunk = FDVideoChunk.with {
                    $0.data = jpegData
                    $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                    $0.isLast = false
                }
                
                try? self?.streamCall?.sendMessage(chunk)
                frameCount += 1
            }
            
            // 스트림 종료
            let finalChunk = FDVideoChunk.with {
                $0.isLast = true
                $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            }
            try? self?.streamCall?.sendMessage(finalChunk)
            try? self?.streamCall?.sendEnd()
            
            DispatchQueue.main.async {
                self?.isPlaying = false
            }
        }
    }
    
    func stopStreaming() {
        player?.pause()
        try? streamCall?.sendEnd()
        isPlaying = false
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct ConnectView: View {
    @StateObject private var streamService = VideoStreamService()
    
    var body: some View {
        VStack {
            if streamService.isPlaying,
               let player = streamService.player {
                VideoPlayerView(player: player)
                    .frame(height: 300)
            }
            
            if streamService.fireDetected {
                Text("🔥 Fire Detected!")
                    .foregroundColor(.red)
                    .font(.headline)
            }
            
            Button(streamService.isPlaying ? "Stop Streaming" : "Start Streaming") {
                if streamService.isPlaying {
                    streamService.stopStreaming()
                } else if let videoUrl = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
                    streamService.streamVideo(fileURL: videoUrl)
                }
            }
            .padding()
            .background(streamService.isPlaying ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    ConnectView()
}
