package main

import (
	"context"
	"flag"
	"io"
	"log"
	"os"
	"time"

	pb "github.com/GDG-on-Campus-KHU/SC5-APP/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	// 커맨드 라인 플래그 설정
	videoPath := flag.String("video", `/home/user/test.mp4`, "Path to video file") // local test 환경에 맞춰서 경로 변경하기
	serverAddr := flag.String("server", "localhost:50051", "Server address")
	chunkSize := flag.Int("chunk-size", 1024*1024, "Size of each chunk in bytes")
	flag.Parse()

	if *videoPath == "" {
		log.Fatal("Please provide video path using -video flag")
	}

	// 비디오 파일 열기
	video, err := os.Open(*videoPath)
	if err != nil {
		log.Fatalf("Failed to open video file: %v", err)
	}
	defer video.Close()

	// gRPC 연결 설정
	conn, err := grpc.Dial(*serverAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer conn.Close()

	client := pb.NewFireDetectionServiceClient(conn)
	stream, err := client.StreamVideo(context.Background())
	if err != nil {
		log.Fatalf("Failed to create stream: %v", err)
	}

	// 응답 수신을 위한 고루틴
	go receiveResponses(stream)

	// 청크 단위로 비디오 전송
	buffer := make([]byte, *chunkSize)
	for {
		n, err := video.Read(buffer)
		if err == io.EOF {
			// 마지막 청크 전송
			if n > 0 {
				if err := sendChunk(stream, buffer[:n], true); err != nil {
					log.Printf("Failed to send last chunk: %v", err)
				}
			}
			break
		}
		if err != nil {
			log.Fatalf("Failed to read video file: %v", err)
		}

		if err := sendChunk(stream, buffer[:n], false); err != nil {
			log.Fatalf("Failed to send chunk: %v", err)
		}
	}

	// 스트림 종료
	if err := stream.CloseSend(); err != nil {
		log.Printf("Failed to close stream: %v", err)
	}

	// 잠시 대기하여 마지막 응답을 받을 수 있도록 함
	time.Sleep(time.Second)
}

func sendChunk(stream pb.FireDetectionService_StreamVideoClient, data []byte, isLast bool) error {
	chunk := &pb.VideoChunk{
		Data:      data,
		Timestamp: time.Now().UnixNano() / int64(time.Millisecond),
		IsLast:    isLast,
	}

	if err := stream.Send(chunk); err != nil {
		return err
	}

	log.Printf("Sent chunk of size %d bytes", len(data))
	return nil
}

func receiveResponses(stream pb.FireDetectionService_StreamVideoClient) {
	for {
		response, err := stream.Recv()
		if err == io.EOF {
			log.Println("Server closed the stream")
			return
		}
		if err != nil {
			log.Printf("Error receiving response: %v", err)
			return
		}

		log.Printf("Received response: detected=%v, message=%s, timestamp=%d",
			response.Detected, response.Message, response.Timestamp)
	}
}
