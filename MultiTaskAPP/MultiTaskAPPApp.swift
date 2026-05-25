//
//  MultiTaskAPPApp.swift
//  MultiTaskAPP
//
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct MultiTaskAPPApp: App {
    // 🌟 建立一個全域變數，用來控制目前到底該看「登入頁」還是「大廳」
    @State private var isUserLoggedIn: Bool = false

    init() {
        // 初始化 Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isUserLoggedIn {
                    // 🏠 狀態 A：已登入，顯示你的專案大廳
                    ProjectListView()
                } else {
                    // 🔒 狀態 B：未登入，顯示登入/註冊頁
                    AuthView()
                }
            }
            .animation(.easeInOut, value: isUserLoggedIn) // 🌟 讓切換時有平滑的淡入淡出動畫
            .onAppear {
                // 1. 一開 App 檢查：如果之前就登入過，直接進大廳
                if Auth.auth().currentUser != nil {
                    isUserLoggedIn = true
                }
            }
            // 🌟 2. 監聽大廳傳來的「登出廣播」
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("userLoggedOut"))) { _ in
                isUserLoggedIn = false // 收到廣播，秒切回登入頁
            }
            // 🌟 3. 監聽登入頁傳來的「登入成功廣播」
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("userLoggedIn"))) { _ in
                isUserLoggedIn = true // 收到廣播，秒切進專案大廳
            }
        }
    }
}
