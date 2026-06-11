//
//  NotificationManager.swift
//  MultiTaskAPP
//
//  處理通知的核心
//

import Foundation
import UserNotifications

// 💡 1. 必須繼承 NSObject 並實作 UNUserNotificationCenterDelegate
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    // 💡 2. 初始化時設定代理 (Delegate)
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - 要求推播權限
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("❌ 授權通知失敗: \(error.localizedDescription)")
            } else if granted {
                print("✅ 使用者已允許通知權限")
            } else {
                print("⚠️ 使用者拒絕了通知權限")
            }
        }
    }
    
    // MARK: - 設定任務截止日期的本地通知
    func scheduleDeadlineNotification(taskTitle: String, deadline: Date, taskId: String) {
        let content = UNMutableNotificationContent()
        content.title = "任務即將到期提醒 ⏰"
        content.body = "你的任務「\(taskTitle)」即將截止，請盡快完成！"
        content.sound = .default
        
        // 為了測試方便，提前 1 分鐘
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -1, to: deadline) ?? deadline
        
        guard triggerDate > Date() else {
            // 💡 加上 print 讓我們知道是不是因為時間已經過去而被擋下
            print("⚠️ 任務「\(taskTitle)」的通知時間 (\(triggerDate)) 已經過去，不設定推播")
            return
        }
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: taskId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 設定任務推播失敗: \(error.localizedDescription)")
            } else {
                print("✅ 成功設定推播！任務：\(taskTitle)，將於 \(triggerDate) 提醒")
            }
        }
    }
    
    // MARK: - 2. 個人防呆：每日早報定時提醒 (升級為動態時間)
    /// 在使用者設定的時間發送通知，提醒使用者今天要做的事情
    // 🌟 修改：加入 hour 和 minute 參數
    func scheduleDailySummaryNotification(remainingTasksCount: Int, hour: Int, minute: Int) {
        // 如果今天完全沒有未完成任務，就不吵使用者
        guard remainingTasksCount > 0 else {
            print("⏭️ 因為沒有未完成任務，取消每日通知排程。")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "☀️ 每日通知：今天又是執行任務的一天！"
        content.body = "早安！今天還有 \(remainingTasksCount) 個任務等著你完成，請盡快執行！"
        content.sound = .default
        
        // 🌟 修改：設定為使用者自訂的時間觸發
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // repeats: true 代表每天這個時間點都會自動響鈴
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 測試用：如果要即時測試，可以取消下方兩行的註解（測試完記得改回來）
        // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(identifier: "daily_summary_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 設定每日通知失敗: \(error.localizedDescription)")
            } else {
                print("✅ 成功設定每日通知！將在每天 \(String(format: "%02d:%02d", hour, minute)) 提醒")
            }
        }
    }

    // MARK: - 3. 抓取手機通知列中的歷史通知紀錄 (新功能)
    /// 從 iOS 系統底層非同步讀取目前已經傳送（Delivered）到手機上的通知列表
    func fetchDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            // 因為讀取系統通知是背景線程，回傳結果時必須切換回主線程 (Main Thread) 才能安全更新 UI
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate (處理前景通知)
    
    // 💡 3. 這個方法告訴 iOS：當 App 正在畫面上 (前景) 時收到通知，該怎麼呈現？
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 要求系統即使 App 開著，也要顯示橫幅 (.banner) 並播放聲音 (.sound)
        completionHandler([.banner, .sound])
    }
}
