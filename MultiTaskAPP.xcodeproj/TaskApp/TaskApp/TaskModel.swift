//
//  TaskMode.swift
//  TaskApp
//
//  Created by 訪客使用者 on 2026/5/25.
//

import Foundation

enum TaskStatus: String, CaseIterable {
    case todo = "待處理"
    case inProgress = "進行中"
    case done = "已完成"
}

struct TaskItem: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var assignee: String 
    var status: TaskStatus
}
