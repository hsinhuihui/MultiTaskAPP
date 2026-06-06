// TaskManager.swift
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
        // 🌟 關鍵修改：因為 Firebase 存的是 Email，所以這裡要抓當前用戶的 email
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("無法取得使用者任務：找不到使用者的 Email")
            return
        }
        
        listenerRegistration?.remove()
        
        // 🌟 關鍵修改：使用 "assignee" 欄位，並且拿 currentUserEmail 來比對
        listenerRegistration = db.collection("project_tasks")
            .whereField("assignee", isEqualTo: currentUserEmail)
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
            }
    }
    
    // 💡 配合資料模型更新：改為切換 isCompleted 布林值
    func toggleTaskStatus(task: TodoTask) {
        let newStatus = !task.isCompleted
        db.collection("project_tasks").document(task.id).updateData([
            "isCompleted": newStatus
        ])
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
