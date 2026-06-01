import SwiftUI
import FirebaseCore // 引入 Firebase 核心套件
import FirebaseAuth // 🌟 必須補上這一行，否則 Xcode 找不到 Auth.auth()
import UserNotifications // 推播與本地通知系統框架

@main
struct MultiTaskAPPApp: App {
    // 🌟 全域狀態：控制現在該顯示「登入畫面」還是「專案大廳」
    @State private var isUserLoggedIn: Bool = false

    init() {
        // 🔒 只在這裡初始化一次 Firebase，原本上面的 AppDelegate 就可以丟掉了！
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isUserLoggedIn {
                    ProjectListView() 
                } else {
                    AuthView()
                }
            }
            .animation(.easeInOut, value: isUserLoggedIn) // 讓切換畫面時有平滑的淡入淡出動畫
            .onAppear {
                // 1. 順便在這裡觸發你寫在下面的「請求通知權限」彈窗
                requestNotificationPermission()
                
                // 2. 檢查上次使用者是否登入過，有的話直接進大廳
                if Auth.auth().currentUser != nil {
                    isUserLoggedIn = true
                }
            }
            // 🌟 核心：接收到登入畫面傳來的「 userLoggedIn 」廣播時，秒切進大廳！
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("userLoggedIn"))) { _ in
                isUserLoggedIn = true
            }
            // 🌟 核心：接收到大廳傳來的「 userLoggedOut 」廣播時，秒切回登入頁！
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("userLoggedOut"))) { _ in
                isUserLoggedIn = false
            }
        }
    }
}

// 允許通知權限（維持原樣，移到最下面放著）
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
        if success {
            print("✅ 使用者同意開啟通知！")
        } else if let error = error {
            print("❌ 權限請求失敗: \(error.localizedDescription)")
        }
    }
}
