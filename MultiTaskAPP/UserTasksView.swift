//
//  UserTasksView.swift
//  MultiTaskAPP
//
//  Created by 訪客使用者 on 2026/6/1.
//

import Foundation
import SwiftUI

struct UserTasksView: View {
    // 假設這是從 TaskManager 取得並過濾出「屬於當前使用者」的任務
    @State private var tasks: [TodoTask] = []
    
    var body: some View {
        NavigationStack {
            List {
                // 第一層：依日期展開 (例如：6/12 (一))
                ForEach(groupedByDate, id: \.dateString) { dateGroup in
                    DisclosureGroup(dateGroup.dateString) {
                        
                        // 第二層：依時間展開 (例如：12:00)
                        ForEach(dateGroup.timeGroups, id: \.timeString) { timeGroup in
                            DisclosureGroup(timeGroup.timeString) {
                                
                                // 第三層：顯示任務清單 (例如：1. 寫簡報)
                                ForEach(Array(timeGroup.tasks.enumerated()), id: \.element.id) { index, task in
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundColor(.gray)
                                        Text(task.title)
                                            .strikethrough(task.status == .done, color: .gray)
                                        Spacer()
                                        // 狀態小標籤
                                        Text(task.status.rawValue)
                                            .font(.caption2)
                                            .padding(4)
                                            .background(statusColor(task.status).opacity(0.2))
                                            .foregroundColor(statusColor(task.status))
                                            .cornerRadius(4)
                                    }
                                    .padding(.leading, 8)
                                    .padding(.vertical, 2)
                                }
                            }
                            .font(.headline) // 時間層級的字體稍微強調
                        }
                    }
                    .font(.title3.bold()) // 日期層級的字體再放大一點
                }
            }
            .navigationTitle("我的專屬任務")
            .onAppear {
                loadMockData() // 載入測試資料
            }
        }
    }
    
    // MARK: - 輔助函式與分組邏輯
    
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .todo: return .gray
        case .inProgress: return .orange
        case .done: return .green
        }
    }
    
    // 用來儲存分組後結構的型別
    struct DateGroup {
        let dateString: String
        let timeGroups: [TimeGroup]
    }
    struct TimeGroup {
        let timeString: String
        let tasks: [TodoTask]
    }
    
    // 動態計算分組資料
    private var groupedByDate: [DateGroup] {
        // 1. 過濾出有時間的任務
        let validTasks = tasks.filter { $0.dueDate != nil }
        
        // 2. 按照「日期字串」分組 (例如："6/12 (一)")
        let dateDictionary = Dictionary(grouping: validTasks) { task -> String in
            dateFormatter.string(from: task.dueDate!)
        }
        
        // 3. 整理成陣列並排序
        return dateDictionary.map { dateKey, tasksInDate in
            
            // 4. 在每個日期內，按照「時間字串」分組 (例如："12:00")
            let timeDictionary = Dictionary(grouping: tasksInDate) { task -> String in
                timeFormatter.string(from: task.dueDate!)
            }
            
            // 5. 整理時間分組並依時間排序
            let timeGroups = timeDictionary.map { timeKey, tasksInTime in
                TimeGroup(timeString: timeKey, tasks: tasksInTime.sorted(by: { $0.dueDate! < $1.dueDate! }))
            }.sorted { $0.timeString < $1.timeString }
            
            return DateGroup(dateString: dateKey, timeGroups: timeGroups)
        }
        .sorted { $0.dateString < $1.dateString } // 日期排序
    }
    
    // MARK: - 日期格式化工具
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)" // 格式：6/12 (週一)
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 格式：12:00
        return formatter
    }
    
    // MARK: - 產生測試用的假資料
    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let time1 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        let time2 = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: today)!
        let time3 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow)!
        
        tasks = [
            TodoTask(title: "寫簡報", status: .inProgress, dueDate: time1),
            TodoTask(title: "健身", status: .todo, dueDate: time1),
            TodoTask(title: "與設計師開會", status: .todo, dueDate: time2),
            TodoTask(title: "提交專案進度", status: .todo, dueDate: time3)
        ]
    }
}

#Preview {
    UserTasksView()
}
