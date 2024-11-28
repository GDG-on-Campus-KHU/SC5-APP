// server/main.go
package main

import (
    "fmt"
    "io"
    "log"
    "net"
    pb "fire-detection/pb"
    "google.golang.org/grpc"
    "time"
)

type server struct {
    pb.UnimplementedFireDetectionServiceServer
}

func (s *server) StreamVideo(stream pb.FireDetectionService_StreamVideoServer) error {
    log.Println("Started new video stream")
    
    for {
        chunk, err := stream.Recv()
        if err == io.EOF {
            return nil
        }
        if err != nil {
            return fmt.Errorf("error receiving chunk: %v", err)
        }

        // 청크 수신 로그
        log.Printf("Received chunk of size %d bytes at timestamp %v", 
            len(chunk.Data), chunk.Timestamp)

        // 더미 화재 감지 처리 (실제로는 여기서 AI 모델 처리)
        response := &pb.VideoResponse{
            Detected:  false,
            Message:   "Processing video chunk...",
            Timestamp: time.Now().UnixNano() / int64(time.Millisecond),
        }

        if err := stream.Send(response); err != nil {
            return fmt.Errorf("error sending response: %v", err)
        }

        if chunk.IsLast {
            log.Println("Received last chunk, stream complete")
            break
        }
    }

    return nil
}

func main() {
    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("failed to listen: %v", err)
    }

    s := grpc.NewServer()
    pb.RegisterFireDetectionServiceServer(s, &server{})

    log.Printf("Server listening at %v", lis.Addr())
    if err := s.Serve(lis); err != nil {
        log.Fatalf("failed to serve: %v", err)
    }
}