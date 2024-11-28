//
//  ContentView.swift
//  HomeCamProject
//
//  Created by 박현빈 on 11/28/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
       
       
        VStack(spacing: 0) {
            // 상단 도형
            Color.teal // 상단 배경색
                .frame(height: 70)
                .ignoresSafeArea(edges: .top)
        }
        
        
        
        TabView {
            // Left Tab: 기록
            ArchiveView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("기록")
                }
            
            // Center Tab: Family
            CameraListView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("홈캠")
                }
            
            // Right Tab: 설정
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
        }
    }
}


    // MARK: - Camera List View
struct CameraListView: View {
    let cameras = [
        ("거실", "livingroom"), // 이미지 파일명
        ("안방", "bedroom")    // 이미지 파일명
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                List(cameras, id: \.0) { camera in
                    NavigationLink(destination: CameraDetailView(cameraName: camera.0)) {
                        HStack {
                            Image(camera.1)
                                .resizable()
                                .frame(width: 100, height: 60)
                                .cornerRadius(8)
                            Text(camera.0)
                                .font(.headline)
                            Spacer()
                            //Toggle(isOn: .constant(true), label: { EmptyView() })
                              //  .labelsHidden()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("홈캠")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
                
                
                Button(action: {
                    // CCTV 추가 버튼 동작
                }) {
                    Text("CCTV 추가")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}

    // MARK: - Camera Detail View
    struct CameraDetailView: View {
        let cameraName: String
        
        var body: some View {
            VStack {
                Text("\(cameraName) 영상")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
            .navigationTitle(cameraName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Archive View
    struct ArchiveView: View {
        var body: some View {
            Text("기록보관실")
                .font(.largeTitle)
                .padding()
        }
    }

    // MARK: - Settings View
    struct SettingsView: View {
        var body: some View {
            Text("설정")
                .font(.largeTitle)
                .padding()
        }
    }

    // MARK: - Preview
    struct FamilyView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }

#Preview {
    ContentView()
}
