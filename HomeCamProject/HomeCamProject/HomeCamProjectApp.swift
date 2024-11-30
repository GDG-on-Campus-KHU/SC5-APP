//
//  HomeCamProjectApp.swift
//  HomeCamProject
//
//  Created by 박현빈 on 11/28/24.
//

import SwiftUI
import GRPC

@main
struct HomeCamProjectApp: App {
    var body: some Scene {
        WindowGroup {
//            ContentView()
            ConnectView()
        }
    }
}
