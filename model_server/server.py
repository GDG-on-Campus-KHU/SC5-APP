import grpc
from concurrent import futures
import torch
import cv2
import numpy as np
import proto.fire_detection_pb2 as fire_detection_pb2
import proto.fire_detection_pb2_grpc as fire_detection_pb2_grpc
import time
import ssl

ssl._create_default_https_context = ssl._create_unverified_context

class FireDetectionService(fire_detection_pb2_grpc.FireDetectionServiceServicer):
    def __init__(self):
        self.model = torch.hub.load('ultralytics/yolov5', 'custom', path='yolov5s_best.pt')
        
    def StreamVideo(self, request_iterator, context):
        for frame_data in request_iterator:
            # 바이트 데이터를 numpy 배열로 변환
            nparr = np.frombuffer(frame_data.data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # 모델 추론
            results = self.model(img)
            detections = results.pandas().xyxy[0]
            fire_detected = 'fire' in detections['name'].values
            
            yield fire_detection_pb2.VideoResponse(
                detected=fire_detected,
                message="Fire detected!" if fire_detected else "No fire",
                timestamp=frame_data.timestamp
            )

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    fire_detection_pb2_grpc.add_FireDetectionServiceServicer_to_server(
        FireDetectionService(), server)
    server.add_insecure_port('[::]:50052')  # Python 서버는 50052 포트 사용
    server.start()
    print("Model Server started on port 50052")
    server.wait_for_termination()

if __name__ == '__main__':
    serve()