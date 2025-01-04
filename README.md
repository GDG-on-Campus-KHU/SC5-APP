# 홈캠 영상을 통한 화재 감지 및 알람 서비스

제1회-스프린트챌린지-5조-APP
- - - -
## **1. 프로젝트 개요**
- 실시간 영상 스트리밍 및 화재 감지 소프트웨어
- 홈캠 혹은 카메라를 통해 실시간으로 화재를 인식하고 사용자에게 알림
- 화재 경보기에 잦은 오류가 발생, 교차 검증으로 이를 대체 혹은 보완
- 이용자가 홈캠을 통해 화재를 사전에 인식하여, 집을 비운 시간에도 반려동물 혹은 자녀를 재난 상황으로부터 실시간으로 케어
    - 현실적 문제로 홈캠을 통한 실시간 감지 대신, 기존에 저장된 영상에서 화재 발생 시에 감지하는 형태로 구현.

## **2. 서비스 아키텍처**
<img width="1000" alt="image" src="https://github.com/user-attachments/assets/32bf8d84-d471-4b08-8931-c4ca42c4ba61" />

## **3. 프로그램 소개**

https://github.com/user-attachments/assets/072093e9-e317-411e-a6e3-fdf7f1293087

### **1) Application Client**

- SwiftUI 프레임워크 활용
    - GUI 및 백엔드와 연결
- Combine(실시간 처리), AVkit 등의 라이브러리 사용
- 스트리밍 통해 홈캠 영상 확인, 화재 감지 시 알림 메시지 전달

### **2) Server(GRPC 활용)**

- Bidirectional Streaming(양방향 스트리밍) 형태로 client(swift)와 ai model server(python) 사이를 연결
- 중간 전달자 역할
- golang 사용

### **3) YOLOv5**

- 실시간 객체 탐지에 적합한 딥러닝 모델
    - 실시간 물체 탐지 기능: input 영상을 frame 단위로 분할한 뒤 각 이미지에서 목표를 탐지
- python으로 학습 및 사용

## **4. 기술 스택**

- [Mobile] Swift
- [BackEnd] Go + Python
- [AI] volov5 (Python)
