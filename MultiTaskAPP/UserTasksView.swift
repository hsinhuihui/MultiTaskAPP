// UserTasksView.swift
import Foundation
import SwiftUI

struct UserTasksView: View {
    // 💡 替換成真實的 TaskManager
    @State private var taskManager = TaskManager()
    
    var body: some View {
        NavigationStack {
            List {
                // 第一層：依日期展開
                ForEach(groupedByDate, id: \.dateString) { dateGroup in
                    DisclosureGroup(dateGroup.dateString) {
                        
                        // 第二層：依時間展開
                        ForEach(dateGroup.timeGroups, id: \.timeString) { timeGroup in
                            DisclosureGroup(timeGroup.timeString) {
                                
                                // 第三層：顯示任務清單
                                ForEach(Array(timeGroup.tasks.enumerated()), id: \.element.id) { index, task in
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundColor(.gray)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.title)
                                                // 💡 修改：依據 isCompleted 決定是否畫刪除線
                                                .strikethrough(task.isCompleted, color: .gray)
                                            
                                            if let projectName = task.projectName {
                                                Text(projectName)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // 💡 修改：直接使用 task.isCompleted 來判斷
                                        let isDone = task.isCompleted
                                        Text(isDone ? "已完成" : "未完成")
                                            .font(.caption2)
                                            .padding(4)
                                            .background(isDone ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                            .foregroundColor(isDone ? .green : .gray)
                                            .cornerRadius(4)
                                    }
                                    .padding(.leading, 8)
                                    .padding(.vertical, 2)
                                }
                            }
                            .font(.headline)
                        }
                    }
                    .font(.title3.bold())
                }
            }
            .navigationTitle("我的任務")
            .onAppear {
                // 💡 畫面出現時，呼叫 Firebase 監聽當前使用者的任務
                taskManager.listenToUserTasks()
            }
        }
    }
    
    // MARK: - 輔助函式與分組邏輯
    
    struct DateGroup {
        let dateString: String
        let timeGroups: [TimeGroup]
    }
    struct TimeGroup {
        let timeString: String
        let tasks: [TodoTask]
    }
    
    private var groupedByDate: [DateGroup] {
        // 💡 1. 從 taskManager 取出真實資料，並過濾出有時間的任務
        let validTasks = taskManager.tasks.filter { $0.dueDate != nil }
        
        let dateDictionary = Dictionary(grouping: validTasks) { task -> String in
            dateFormatter.string(from: task.dueDate!)
        }
        
        return dateDictionary.map { dateKey, tasksInDate in
            let timeDictionary = Dictionary(grouping: tasksInDate) { task -> String in
                timeFormatter.string(from: task.dueDate!)
            }
            
            let timeGroups = timeDictionary.map { timeKey, tasksInTime in
                // 依時間排序
                TimeGroup(timeString: timeKey, tasks: tasksInTime.sorted(by: { $0.dueDate! < $1.dueDate! }))
            }.sorted { $0.timeString < $1.timeString }
            
            return DateGroup(dateString: dateKey, timeGroups: timeGroups)
        }
        .sorted { $0.dateString < $1.dateString } // 依日期字串排序
    }
    
    // MARK: - 日期格式化工具
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

#Preview {
    UserTasksView()
}
