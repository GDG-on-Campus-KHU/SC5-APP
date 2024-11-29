package main

import (
	"context"
	"io"
	"log"
	"time"
	"fmt"

    "gocv.io/x/gocv"         // OpenCV 바인딩
	pb "github.com/GDG-on-Campus-KHU/SC5-APP/proto"
	"google.golang.org/grpc"
)

func main() {
    // gRPC 연결 설정
    conn, err := grpc.Dial("localhost:50051", grpc.WithInsecure())
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewFireDetectionServiceClient(conn)

    // 비디오 파일 경로 설정
    videoPath := "../../input.mp4"
    if err := streamVideo(client, videoPath); err != nil {
        log.Fatalf("Error streaming video: %v", err)
    }
}

func streamVideo(client pb.FireDetectionServiceClient, videoPath string) error {
    // 비디오 캡처 객체 생성
    video, err := gocv.VideoCaptureFile(videoPath)
    if err != nil {
        return fmt.Errorf("error opening video file: %v", err)
    }
    defer video.Close()

    // 양방향 스트림 생성
    ctx := context.Background()
    stream, err := client.StreamVideo(ctx)
    if err != nil {
        return fmt.Errorf("error creating stream: %v", err)
    }

    // 응답을 처리하는 고루틴
    go func() {
        for {
            response, err := stream.Recv()
            if err == io.EOF {
                return
            }
            if err != nil {
                log.Printf("Error receiving response: %v", err)
                return
            }

            if response.Detected {
                // 화재 감지시 알림
                log.Printf("🔥 Fire detected at timestamp: %v", 
                    time.Unix(0, response.Timestamp).Format("15:04:05"))
                // 여기에 알림 로직 추가 (소리, 시스템 알림 등)
            }
        }
    }()

    // 프레임 읽기 및 전송
    frame := gocv.NewMat()
    defer frame.Close()

    for {
        if ok := video.Read(&frame); !ok {
            break
        }
        if frame.Empty() {
            continue
        }

        // 프레임을 JPEG로 인코딩
        buf, err := gocv.IMEncode(gocv.JPEGFileExt, frame)
        if err != nil {
            return fmt.Errorf("error encoding frame: %v", err)
        }

        // 프레임 전송
        if err := stream.Send(&pb.VideoChunk{
            Data:      buf.GetBytes(),
            Timestamp: time.Now().UnixNano(),
            IsLast:    false,
        }); err != nil {
            return fmt.Errorf("error sending frame: %v", err)
        }

        // 적절한 프레임 레이트 유지를 위한 대기
        time.Sleep(33 * time.Millisecond)  // ~30fps
    }

    // 마지막 프레임 표시
    if err := stream.Send(&pb.VideoChunk{
        Data:      nil,
        Timestamp: time.Now().UnixNano(),
        IsLast:    true,
    }); err != nil {
        return fmt.Errorf("error sending final frame: %v", err)
    }

    // 스트림 종료
    if err := stream.CloseSend(); err != nil {
        return fmt.Errorf("error closing stream: %v", err)
    }

    return nil
}