import Foundation

// 任務狀態（三段式）
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To-do"
    case inProgress = "In Progress"
    case done = "Done"
}
