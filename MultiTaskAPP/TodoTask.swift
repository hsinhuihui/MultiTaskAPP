// TodoTask.swift
import Foundation

// 任務資料模型
struct TodoTask: Identifiable, Codable {
    var id: String           // 💡 Firebase 裡已經有 id 欄位，且為字串
    var title: String
    var isCompleted: Bool    // 💡 Firebase 裡用的是 isCompleted (布林值)
    var dueDate: Date?       // 留在 Swift 裡叫 dueDate 比較直覺
    var assignee: String?    // 💡 Firebase 裡叫 assignee (存的是 Email)
    var projectId: String?
    var projectName: String? // Firebase 裡面目前沒有這個，如果沒資料它就會是 nil
    
    // 💡 翻譯蒟蒻：將 Swift 變數對應到 Firebase 的真實欄位
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted          // 完全對應
        case dueDate = "deadline" // 🌟 告訴 Swift：Firebase 裡的名稱叫 deadline
        case assignee             // 完全對應
        case projectId
        case projectName
    }
}
