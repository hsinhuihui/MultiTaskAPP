//
//  TaskManager.swift
//  TaskApp
//
//  Created by 訪客使用者 on 2026/5/25.
//

import SwiftUI
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projectMembers: [String] = ["小明", "小華", "阿哲", "未指定"]
    
    func addMember(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty && !projectMembers.contains(trimmedName) {
            projectMembers.append(trimmedName)
        }
    }
    
    func addTask(title: String, description: String, dueDate: Date, assignee: String) {
        let newTask = TaskItem(
            title: title,
            description: description,
            dueDate: dueDate,
            assignee: assignee,
            status: .todo
        )
        tasks.append(newTask)
    }
    
    func updateTaskStatus(taskID: UUID, newStatus: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == taskID }) {
            tasks[index].status = newStatus
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}
