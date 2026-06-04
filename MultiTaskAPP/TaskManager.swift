// TaskManager.swift
import SwiftUI
import Foundation
import FirebaseFirestore

@Observable
class TaskManager {
    var tasks: [TodoTask] = []
    private var db = Firestore.firestore()
    
    // 💡 新增：用來儲存 Firebase 的監聽器，方便在不需要時移除
    private var listenerRegistration: ListenerRegistration?
    
    // 💡 修改：傳入 projectId，只抓取該專案的任務
    func listenToTasks(for projectId: String) {
        // 先移除舊的監聽器，避免重複監聽
        listenerRegistration?.remove()
        
        // 針對 tasks 集合中，projectId 符合的任務進行監聽
        listenerRegistration = db.collection("tasks")
            .whereField("projectId", isEqualTo: projectId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                // 即時更新 @Observable 的 tasks 陣列，SwiftUI 畫面會自動重繪
                self.tasks = documents.compactMap { doc -> TodoTask? in
                    try? doc.data(as: TodoTask.self)
                }
            }
    }
    
    // 更新雲端狀態
    func updateTaskStatus(task: TodoTask, newStatus: TaskStatus) {
        db.collection("tasks").document(task.id.uuidString).updateData([
            "status": newStatus.rawValue
        ])
    }
    
    // 物件銷毀時記得移除監聽
    deinit {
        listenerRegistration?.remove()
    }
}
