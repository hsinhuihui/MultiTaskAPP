//
//  TaskManager.swift
//  MultiTaskAPP
//

import SwiftUI
import Foundation
import FirebaseFirestore

@Observable // 最新的官方 @Observable
class TaskManager {
    // 直接宣告變數，SwiftUI 就會自動智慧監聽變動
    var tasks: [TodoTask] = []
    private var db = Firestore.firestore()
    
    // 監聽雲端資料庫
    func listenToTasks() {
        db.collection("tasks").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }
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
}
