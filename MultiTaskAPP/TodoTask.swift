// TodoTask.swift
import Foundation

// 1. 定義任務狀態
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To-do"
    case inProgress = "In Progress"
    case done = "Done"
}

// 2. 任務資料模型
struct TodoTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var status: TaskStatus
    var dueDate: Date?
    var assigneeId: String?
    // 💡 新增：加入專案 ID，以便區分該任務屬於哪個專案
    var projectId: String?
}
