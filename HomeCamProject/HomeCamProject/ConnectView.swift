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

// GRPC 채널 생성 예시

class VideoStreamService {
    private var client: FDFireDetectionServiceNIOClient?
    private var streamCall: BidirectionalStreamingCall<FDVideoChunk, FDVideoResponse>?
    
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
        
        // 서버로부터의 응답을 처리할 스트림 콜 설정
        streamCall = client.streamVideo { response in
            print("Received response from server: \(response.message)")
            if response.detected {
                print("Fire detected at timestamp: \(response.timestamp)")
            }
        }
        
        do {
            let videoData = try Data(contentsOf: fileURL)
            let chunkSize = 1024 * 1024  // 1MB 단위로 청크 생성
            let chunks = stride(from: 0, to: videoData.count, by: chunkSize).map {
                videoData[$0..<min($0 + chunkSize, videoData.count)]
            }
            
            // 각 청크를 순차적으로 전송
            for (index, chunkData) in chunks.enumerated() {
                let isLast = index == chunks.count - 1
                let chunk = FDVideoChunk.with {
                    $0.data = chunkData
                    $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                    $0.isLast = isLast
                }
                
                print("..")
                try streamCall?.sendMessage(chunk)

                
                print("Sent chunk \(index) of size \(chunkData.count) bytes.")
                
                // 청크 간 약간의 딜레이를 줄 수 있습니다
                Thread.sleep(forTimeInterval: 0.1)
            }
            
        } catch {
            print("Error streaming video: \(error)")
        }
    }
    
    func stopStreaming() {
        try? streamCall?.sendEnd()
    }
}

struct ConnectView: View {
    private let streamService = VideoStreamService()
    
    var body: some View {
        Button("Start Streaming") {
            if let videoUrl = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
                streamService.streamVideo(fileURL: videoUrl)
            }
        }
    }
}


