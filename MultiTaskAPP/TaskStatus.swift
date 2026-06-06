//
//  TaskStatus.swift
//  MultiTaskAPP
//
//  Created by kung on 2026/6/7.
//


import Foundation

// 1. 任務狀態（三段式）
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To-do"
    case inProgress = "In Progress"
    case done = "Done"
}

// 2. 任務資料模型
struct TodoTask: Identifiable, Codable {
    var id: String
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var assignee: String?
    var projectId: String?
    var projectName: String?
    var status: TaskStatus?  // 🌟 新增，optional 讓舊資料不會壞掉

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case dueDate = "deadline"
        case assignee
        case projectId
        case projectName
        case status
    }
}