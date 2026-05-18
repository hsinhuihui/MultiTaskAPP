import SwiftUI
import FirebaseCore // 引入 Firebase 核心套件

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
