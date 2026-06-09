import Foundation
import SwiftUI

struct UserTasksView: View {
    @State private var taskManager = TaskManager()
    
    // 用來記錄目前「被收起」的日期群組
    @State private var collapsedDates: Set<Date> = []
    
    // 🎨 暖色調調色盤
    private let warmOrange = Color(red: 0.95, green: 0.48, blue: 0.12)     // 主色：溫暖深橘
    private let lightWarmOrange = Color(red: 1.0, green: 0.94, blue: 0.88) // 輔色：淺琥珀米色
    private let warmBackground = Color(red: 0.98, green: 0.97, blue: 0.95) // 背景：優雅暖白/燕麥色
    
    // 💡 新增：全域任務統計數據
    private var totalTasksCount: Int {
        taskManager.tasks.count
    }
    
    private var completedTasksCount: Int {
        taskManager.tasks.filter { $0.status == .done }.count
    }
    
    private var completionRate: Double {
        totalTasksCount > 0 ? Double(completedTasksCount) / Double(totalTasksCount) : 0.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 全域暖色調背景
                warmBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        // 💡 新增：頂部全域進度總覽面板
                        if totalTasksCount > 0 {
                            overviewProgressCard
                                .padding(.top, 5)
                        }
                        
                        // 依日期展開卡片列表
                        ForEach(groupedByDate, id: \.date) { dateGroup in
                            dateSection(for: dateGroup)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("我的任務")
            .onAppear {
                taskManager.listenToUserTasks()
            }
        }
    }
    
    // MARK: - 🎯 頂部全域進度總覽卡片
    private var overviewProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("任務完成率")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    // 🌟 數值顯示：完成任務數 / 所有任務數
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(completedTasksCount)")
                            .font(.system(size: 32, design: .rounded))
                            .bold()
                            .foregroundColor(warmOrange)
                        Text("/")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("\(totalTasksCount)")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("個任務")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 2)
                    }
                }
                
                Spacer()
                
                // 右側百分比顯示
                Text("\(Int(completionRate * 100))%")
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .foregroundColor(warmOrange)
                    .padding(12)
                    .background(lightWarmOrange)
                    .clipShape(Circle())
            }
            
            // 溫暖色調的進度條
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(warmOrange)
                        .frame(width: geo.size.width * completionRate, height: 8)
                        // 當數值改變時，進度條會有流暢的橫向滑動動畫
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completionRate)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: warmOrange.opacity(0.04), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - 📅 日期群組區塊
    @ViewBuilder
    private func dateSection(for dateGroup: DateGroup) -> some View {
        let isCollapsed = collapsedDates.contains(dateGroup.date)
        let groupTotal = dateGroup.tasks.count
        let groupCompleted = dateGroup.tasks.filter { $0.status == .done }.count
        
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isCollapsed {
                        collapsedDates.remove(dateGroup.date)
                    } else {
                        collapsedDates.insert(dateGroup.date)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title2)
                        .foregroundColor(warmOrange)
                    
                    Text(formatDateTitle(dateGroup.date))
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 💡 修改：將原本的單純數量標籤，改為精確的「完成數/總數 完成」
                    Text("\(groupCompleted)/\(groupTotal) 完成")
                        .font(.caption.bold())
                        .foregroundColor(warmOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(lightWarmOrange)
                        .cornerRadius(10)
                    
                    Image(systemName: "chevron.up")
                        .font(.caption.bold())
                        .foregroundColor(warmOrange)
                        .rotationEffect(.degrees(isCollapsed ? 180 : 0))
                }
                .padding(.bottom, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 任務卡片列表
            if !isCollapsed {
                ForEach(dateGroup.tasks) { task in
                    taskCard(for: task)
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - 🏷️ 單一任務卡片設計
    @ViewBuilder
    private func taskCard(for task: TodoTask) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // 左側：時間與狀態圓圈（一鍵快速完成與智慧退回）
            VStack(spacing: 8) {
                Text(task.dueDate != nil ? timeFormatter.string(from: task.dueDate!) : "--:--")
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
                
                Button {
                    // 💡 智慧判斷邏輯：
                    if task.status == .done {
                        // 1. 如果目前是已完成，要退回前一個狀態 (如果沒有紀錄，預設退回 .todo)
                        let revertStatus = task.previousStatus ?? .todo
                        taskManager.updateTaskStatus(task: task, newStatus: revertStatus)
                    } else {
                        // 2. 如果目前不是已完成，要變成已完成，同時「把現在的狀態存進 previousStatus」
                        taskManager.updateTaskStatus(task: task, newStatus: .done, previousStatus: task.status)
                    }
                } label: {
                    Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.status == .done ? .green : warmOrange)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 45)
            
            // 中間：標題與專案標籤
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(task.status == .done ? .gray : .primary)
                    .strikethrough(task.status == .done, color: .gray)
                
                if let projectName = task.projectName {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(projectName)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(warmOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(lightWarmOrange)
                    .cornerRadius(6)
                }
            }
            
            Spacer()
            
            // 右側：選項按鈕與狀態膠囊
            VStack(alignment: .trailing, spacing: 12) {
                Menu {
                    // 💡 新增：細分狀態調整選單
                    Section(header: Text("變更任務狀態")) {
                        Button {
                            taskManager.updateTaskStatus(task: task, newStatus: .todo)
                        } label: {
                            Label("待處理", systemImage: task.status == .todo ? "checkmark" : "")
                        }
                        
                        Button {
                            taskManager.updateTaskStatus(task: task, newStatus: .inProgress)
                        } label: {
                            Label("進行中", systemImage: task.status == .inProgress ? "checkmark" : "")
                        }
                        
                        Button {
                            taskManager.updateTaskStatus(task: task, newStatus: .done)
                        } label: {
                            Label("已完成", systemImage: task.status == .done ? "checkmark" : "")
                        }
                    }
                    
                    Divider() // 分隔線
                    
                    // 原有的刪除按鈕
                    Button(role: .destructive) {
                        taskManager.deleteTask(task: task)
                    } label: {
                        Label("刪除任務", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(8)
                        .contentShape(Rectangle())
                }
                
                Spacer(minLength: 0)
                
                // 根據三段狀態決定文字與顏色
                let statusText = task.status == .done ? "已完成" : (task.status == .inProgress ? "進行中" : "待處理")
                let statusColor: Color = task.status == .done ? .green : (task.status == .inProgress ? .blue : warmOrange)
                
                Text(statusText)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: warmOrange.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 邏輯與分組架構
    struct DateGroup {
        let date: Date
        let tasks: [TodoTask]
    }
    
    private var groupedByDate: [DateGroup] {
        let validTasks = taskManager.tasks.filter { $0.dueDate != nil }
        
        let grouped = Dictionary(grouping: validTasks) { task -> Date in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: task.dueDate!)
            return Calendar.current.date(from: components) ?? task.dueDate!
        }
        
        return grouped.map { date, tasks in
            let sortedTasks = tasks.sorted { $0.dueDate! < $1.dueDate! }
            return DateGroup(date: date, tasks: sortedTasks)
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - 輔助格式化工具
    private func formatDateTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "明天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日 (E)"
            formatter.locale = Locale(identifier: "zh_Hant_TW")
            return formatter.string(from: date)
        }
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
