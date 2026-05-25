//
//  ContentView.swift
//  MultiTaskAPP
//

import SwiftUI

struct ContentView: View {
    // 暫時用一組假資料模擬專案中的任務清單，測試進度條
    // @State 即時更新畫面資料
    @State private var tasks: [TodoTask] = [
        TodoTask(title: "設計 UI 介面", status: .done),
        TodoTask(title: "串接 Firebase", status: .inProgress),
        TodoTask(title: "測試推播功能", status: .todo),
        TodoTask(title: "修正 Bug", status: .todo)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 呼叫進度條元件，並把目前的 tasks 傳進去
                ProjectProgressView(tasks: tasks)
                    .padding(.horizontal)
                
                // 任務列表，點擊右側狀態按鈕可以直接切換狀態
                List {
                    Section(header: Text("任務清單（點擊狀態可切換測試）")) {
                        // $ 雙向綁定
                        ForEach($tasks) { $task in
                            HStack {
                                Text(task.title)
                                Spacer()
                                
                                // 點擊按鈕會在 To-do -> In Progress -> Done 之間循環切換
                                Button(task.status.rawValue) {
                                    switch task.status {
                                    case .todo: task.status = .inProgress
                                    case .inProgress: task.status = .done
                                    case .done: task.status = .todo
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(statusColor(task.status))
                            }
                        }
                    }
                }
            }
            .navigationTitle("專案任務")
            .background(Color(.systemGroupedBackground))
        }
    }

    // 輔助函式：根據狀態改變按鈕顏色
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .todo: return .gray
        case .inProgress: return .orange
        case .done: return .green
        }
    }
}

// 3. 專案進度條元件
struct ProjectProgressView: View {
    var tasks: [TodoTask]
    
    // 自動計算進度百分比
    private var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let doneCount = tasks.filter { $0.status == .done }.count // 過濾 Done 的任務並計算任務數量
        return Double(doneCount) / Double(tasks.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("專案總進度")
                .font(.headline)
            
            // 進度條線條
            //
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .animation(.default, value: progress) // 讓進度條抽動時有流暢動畫
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text("已完成: \(tasks.filter { $0.status == .done }.count) / 總任務: \(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 4. 預覽畫面
#Preview {
    ContentView()
}
