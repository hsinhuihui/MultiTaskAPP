//
// TaskManager.swift
//

import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable
class TaskManager {
    var tasks: [TodoTask] = []
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func listenToTasks(for projectId: String) {
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("project_tasks")
            .whereField("projectId", isEqualTo: projectId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.tasks = documents.compactMap { doc -> TodoTask? in
                    try? doc.data(as: TodoTask.self)
                }
            }
    }
    
    // 💡 讀取「目前登錄使用者」負責的所有任務
    func listenToUserTasks() {
        guard let user = Auth.auth().currentUser else {
            print("無法取得使用者任務：找不到目前登入的用戶")
            return
        }
        
        let currentUserEmail = user.email ?? ""
        let currentUserName = user.displayName ?? "" // 🌟
        let currentUID = user.uid
        
        listenerRegistration?.remove()
        
        // 💡 改用 OR 邏輯：檢查 assigneeId (新規則) 或 assignee (舊資料相容)
        // 注意：Firebase 組合查詢需要建立索引，如果這裡報錯，請點擊 Xcode 錯誤訊息中的連結即可自動建立
        listenerRegistration = db.collection("project_tasks")
            .whereFilter(Filter.orFilter([
                Filter.whereField("assigneeId", isEqualTo: currentUID),
            ]))
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("讀取任務錯誤: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                
                // 收到資料後，進行「升級」動作
                self.tasks = documents.compactMap { doc in
                    var task = try? doc.data(as: TodoTask.self)
                    
                    // 💡 修改處：確認 assign 的名字或 Email 確實屬於當前使用者，才寫入 UID
                    if task != nil && (task?.assigneeId == nil || task?.assigneeId == "") {
                        // 假設你的任務原本有存 assignee 名字或 Email
                        if task?.assignee == user.displayName || task?.assignee == user.email {
                            self.upgradeTaskAssigneeId(taskId: doc.documentID, newUid: currentUID)
                        }
                    }
                    
                    return task
                }
                
                // 🌟 新增這裡：資料讀取並轉換完成後，為每個任務設定本地通知
                print("====================================")
                print("📡 Firebase 監聽觸發！總共抓到 \(self.tasks.count) 個任務")
                
                for task in self.tasks {
                    print("👉 正在檢查任務：【\(task.title)】")
                    print("   - 目前狀態：\(String(describing: task.status))")
                    print("   - 截止時間：\(String(describing: task.dueDate))")
                    
                    // 💡 加上詳細的防呆檢查
                    if task.status == .done {
                        print("   ⏭️ 跳過排程：因為任務已經完成了")
                        continue
                    }
                    
                    guard let taskDate = task.dueDate else {
                        print("   ❌ 跳過排程：抓不到截止時間 (dueDate 是 nil)！")
                        continue
                    }
                    
                    // 🌟 1. 取得使用者設定的提醒時間，如果沒設定(為 nil)，預設給 600 秒 (10分鐘)
                    // (注意：如果你希望 nil 代表「完全不提醒」，這裡的寫法需要改成直接 continue，但我們先求修復時間差問題)
                    let offset = task.reminderOffset ?? 600

                    // 如果狀態不是 done，且有時間，就會執行到這裡
                    NotificationManager.shared.scheduleDeadlineNotification(
                        taskTitle: task.title,
                        deadline: taskDate,
                        taskId: task.id,
                        offsetInSeconds: offset // 🌟 2. 關鍵修正：把偏移量傳進去！
                    )
                }
                print("====================================")
            }
    }
    
    /// 更新任務的狀態，並同步寫入 Firebase
    func updateTaskStatus(task: TodoTask, newStatus: TaskStatus, previousStatus: TaskStatus? = nil) {
        let db = Firestore.firestore()
        
        // 💡 這裡的安全機制：當狀態是 .done 時，isCompleted 同步寫入 true，其餘寫入 false
        // 這樣可以確保 App 裡其他還在使用 isCompleted 的舊功能不會壞掉！
        let isCompletedValue = (newStatus == .done)
        
        // 準備要更新的資料字典
        var updateData: [String: Any] = [
            "status": newStatus.rawValue,
            "isCompleted": isCompletedValue
        ]
        
        // 💡 如果有傳入「前一次的狀態」，就一併寫入 Firebase 記憶起來
        if let previous = previousStatus {
            updateData["previousStatus"] = previous.rawValue
        }
        
        db.collection("project_tasks").document(task.id).updateData(updateData) { error in
            if let error = error {
                print("❌ 更改任務狀態失敗: \(error.localizedDescription)")
            } else {
                print("✅ 任務狀態已成功更新為: \(newStatus.rawValue)")
            }
        }
    }
    
    // 更新提醒時間，並觸發通知重新排程
    func updateReminder(task: TodoTask, offset: TimeInterval?) {
        let db = Firestore.firestore()
        db.collection("project_tasks").document(task.id).updateData([
            "reminderOffset": offset as Any
        ]) { error in
            if error == nil {
                // 更新 Firebase 成功後，重新排程通知
                // 這裡假設你已經有一個更新通知的方法
                self.rescheduleNotification(for: task, newOffset: offset)
            }
        }
    }
    
    // 💡 自動升級函數：在背景將舊任務補上 UID
    private func upgradeTaskAssigneeId(taskId: String, newUid: String) {
        db.collection("project_tasks").document(taskId).updateData([
            "assigneeId": newUid
        ]) { error in
            if error == nil { print("✅ 任務 \(taskId) 已自動升級並綁定 UID") }
        }
    }

    private func rescheduleNotification(for task: TodoTask, newOffset: TimeInterval?) {
        // 移除舊通知
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id])
        
        // 2. 如果 newOffset 是 nil，代表使用者選擇「不提醒」或取消提醒，就直接 return 結束
        guard let offset = newOffset, let dueDate = task.dueDate else {
            print("🚫 任務【\(task.title)】已設定為不提醒或缺乏截止時間")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkPendingNotifications()
            }
            return
        }
        
        // 如果有設定偏移量且截止時間存在，則重新排程
        if let offset = newOffset, let dueDate = task.dueDate {
            NotificationManager.shared.scheduleDeadlineNotification(
                taskTitle: task.title,
                deadline: dueDate, // 傳入原始截止日期
                taskId: task.id,
                offsetInSeconds: offset // 傳入秒數
            )
            print("✅ 成功重新排程通知：\(task.title)，提前量：\(offset)秒")
            
            // 🌟 呼叫 Debug 函數，延遲 0.5 秒以確保系統排程已生效
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkPendingNotifications()
            }
        } else {
            print("🚫 已取消通知，或缺乏截止時間")
            // 🌟 即使是取消提醒 (不提醒)，我們也印出來確認系統清空了
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkPendingNotifications()
            }
        }
    }
    
    // 💡 刪除指定的個人任務
    func deleteTask(task: TodoTask) {
        db.collection("project_tasks").document(task.id).delete { error in
            if let error = error {
                print("❌ 刪除任務失敗: \(error.localizedDescription)")
            } else {
                print("🗑️ 任務已成功刪除")
            }
        }
    }
    
    // 💡 Debug 專用：印出目前所有排程中的通知
    func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n🔍 --- 通知排程檢查 ---")
            print("💡 目前系統中共有 \(requests.count) 個待發送通知：")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextDate = trigger.nextTriggerDate() {
                    print(" ➡️ 預計觸發時間: \(nextDate) | 任務 ID: \(request.identifier)")
                }
            }
            print("----------------------\n")
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
