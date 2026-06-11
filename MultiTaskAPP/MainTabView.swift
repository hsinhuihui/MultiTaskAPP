//
//  MainTabView.swift
//  MultiTaskAPP
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isUserLoggedIn = true
    
    // 🌟 1. 新增一個專門用來在背景默默監聽個人任務的 TaskManager
    @State private var backgroundTaskManager = TaskManager()
    
    // 🌟 新增這裡：使用 @AppStorage 自動同步存在手機底層的使用者自訂時間（預設早上 08:30）
    @AppStorage("dailyNotificationHour") private var savedHour = 8
    @AppStorage("dailyNotificationMinute") private var savedMinute = 30
    
    // 暖橘愛馬仕核心主題色
    let themeOrange = Color(red: 0.98, green: 0.45, blue: 0.15)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🏠 1. 左邊分頁：專案大廳 (首頁)
            ProjectListView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
                .tag(0)
            
            // ➕ 2. 中間分頁：純點擊用的加號快捷鍵 (點擊時被下方 onChange 攔截，原地跳出小視窗)
            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                }
                .tag(1)
            
            UserTasksView()
                .tabItem {
                    // 🌟 採用專案與進度條質感最合的清單徽章圖示
                    Label("我的任務", systemImage: "list.clipboard.fill")
                }
                .tag(2)
        }
        .onAppear {
            // App 啟動並進入主畫面時，向使用者請求通知權限
            NotificationManager.shared.requestAuthorization()
            
            // 🌟 2. App 一打開，就立刻開始在背景監聽「我的任務」
            backgroundTaskManager.listenToUserTasks()
        }
        // 🌟 3. 將原本在 UserTasksView 的晨報排程邏輯搬到這裡
        .onChange(of: backgroundTaskManager.tasks) { newTasks in
            let incompleteCount = newTasks.filter { $0.status != .done }.count
            print("📱 首頁背景監聽到任務更新！未完成數：\(incompleteCount)，準備設定晨報")
            
            // 🌟 修改這裡：將儲存的自訂時、分傳入排程函數中
            NotificationManager.shared.scheduleDailySummaryNotification(
                remainingTasksCount: incompleteCount,
                hour: savedHour,
                minute: savedMinute
            )
        }
        .tint(themeOrange) // 點擊分頁時，亮起精緻的主題暖橘色高亮
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 1 {
                selectedTab = 0 // 萬分之一秒內立刻彈回首頁大廳，保留卡片列表作為背景
                
                // 廣播給大廳：原地優雅地飄出 A/B 面變身建立專案小視窗
                NotificationCenter.default.post(name: NSNotification.Name("openCreateProjectAlert"), object: nil)
            }
        }
    }
}

// 預覽偵錯畫面
#Preview {
    MainTabView()
}
