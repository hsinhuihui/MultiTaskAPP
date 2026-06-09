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
