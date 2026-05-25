//
//  MultiTaskAPPApp.swift
//  MultiTaskAPP
//
//

import SwiftUI
import FirebaseCore // 引入 Firebase 核心套件
import UserNotifications // 推播與本地通知系統框架

// 建立一個 AppDelegate 來處理 Firebase 的初始化
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // 初始化 Firebase
        return true
    }
}

@main
struct MultiTaskAPPApp: App {
    // 註冊 AppDelegate，讓 App 啟動時執行初始化
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AuthView() // 目前先維持載入預設的 ContentView
        }
    }
}

// 允許通知權限
func requestNotificationPermission() {
    
    // 取得目前這台 iPhone 的中央通知控制中心物件
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
        if success {
            print("使用者同意開啟通知！")
        } else if let error = error {
            print("權限請求失敗: \(error.localizedDescription)")
        }
    }
}
