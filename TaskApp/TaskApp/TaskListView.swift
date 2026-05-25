//
//  TaskListView.swift
//  TaskApp
//
//  Created by 訪客使用者 on 2026/5/25.
//

import SwiftUI

struct TaskListView: View {
    @StateObject var taskManager = TaskManager()
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach($taskManager.tasks) { $task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(task.title)
                                .font(.headline)
                            Spacer()
                            Picker("狀態", selection: $task.status) {
                                ForEach(TaskStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("負責人: \(task.assignee)")
                            Spacer()
                            Text("截止日: \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: taskManager.deleteTask)
            }
            .navigationTitle("待辦事項")
            .toolbar {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskManager: taskManager)
            }
        }
    }
}

#Preview {
    TaskListView()
}

