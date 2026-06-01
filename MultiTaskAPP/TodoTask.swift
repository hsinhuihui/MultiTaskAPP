//
//  TodoTask.swift
//  MultiTaskAPP
//
//  Created by 訪客使用者 on 2026/5/25.
//

import Foundation

// 1. 定義任務狀態
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To-do"
    case inProgress = "In Progress"
    case done = "Done"
}

// 2. 任務資料模型
struct TodoTask: Identifiable, Codable {
    var id = UUID() // 用 UUID() 產生唯一 id
    var title: String
    var status: TaskStatus
    var dueDate: Date? // 任務時間
    var assigneeId: String? // 負責人
}
