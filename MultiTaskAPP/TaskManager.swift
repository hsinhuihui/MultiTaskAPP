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
        
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("project_tasks")
            .whereField("assignee", in: [currentUserEmail, currentUserName])
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("讀取任務錯誤: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                
                self.tasks = documents.compactMap { doc -> TodoTask? in
                    do {
                        return try doc.data(as: TodoTask.self)
                    } catch {
                        print("❌ 解析任務失敗: \(error)")
                        return nil
                    }
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
                    
                    // 如果狀態不是 done，且有時間，就會執行到這裡
                    NotificationManager.shared.scheduleDeadlineNotification(
                        taskTitle: task.title,
                        deadline: taskDate,
                        taskId: task.id
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
    
    deinit {
        listenerRegistration?.remove()
    }
}
