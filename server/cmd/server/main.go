// server/main.go
package main

import (
	"fmt"
	"io"
	"log"
	"net"
    "context"

	pb "github.com/GDG-on-Campus-KHU/SC5-APP/proto"
	"google.golang.org/grpc"
)

type server struct {
    pb.UnimplementedFireDetectionServiceServer
    modelClient pb.FireDetectionServiceClient
}

func NewServer() (*server, error) {
    // Python 모델 서버에 연결
    conn, err := grpc.Dial("localhost:50052", grpc.WithInsecure())
    if err != nil {
        return nil, fmt.Errorf("failed to connect to model server: %v", err)
    }

    modelClient := pb.NewFireDetectionServiceClient(conn)
    
    return &server{
        modelClient: modelClient,
    }, nil
}

func (s *server) StreamVideo(stream pb.FireDetectionService_StreamVideoServer) error {
    // Python 모델 서버와의 스트림 생성
    ctx := context.Background()
    modelStream, err := s.modelClient.StreamVideo(ctx)
    if err != nil {
        return fmt.Errorf("failed to create model stream: %v", err)
    }

    // 결과를 받는 채널 생성
    resultChan := make(chan *pb.VideoResponse)
    errorChan := make(chan error)

    // Python 서버로부터 응답을 받는 고루틴
    go func() {
        for {
            resp, err := modelStream.Recv()
            if err == io.EOF {
                close(resultChan)
                return
            }
            if err != nil {
                errorChan <- fmt.Errorf("error receiving from model: %v", err)
                return
            }
            resultChan <- resp
        }
    }()

    // 클라이언트로부터 프레임을 받아서 Python 서버로 전송
    go func() {
        for {
            frame, err := stream.Recv()
            if err == io.EOF {
                modelStream.CloseSend()
                return
            }
            if err != nil {
                errorChan <- fmt.Errorf("error receiving from client: %v", err)
                return
            }

            if err := modelStream.Send(frame); err != nil {
                errorChan <- fmt.Errorf("error sending to model: %v", err)
                return
            }
        }
    }()

    // 결과 처리 및 클라이언트로 전송
    for {
        select {
        case err := <-errorChan:
            return err
        case resp, ok := <-resultChan:
            if !ok {
                return nil
            }
            if err := stream.Send(resp); err != nil {
                return fmt.Errorf("error sending to client: %v", err)
            }
        }
    }
}

func main() {
    srv, err := NewServer()
    if err != nil {
        log.Fatalf("Failed to create server: %v", err)
    }

    lis, err := net.Listen("tcp", ":50051")  // Go 서버는 50051 포트 사용
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    s := grpc.NewServer()
    pb.RegisterFireDetectionServiceServer(s, srv)
    log.Printf("Server listening at %v", lis.Addr())
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}