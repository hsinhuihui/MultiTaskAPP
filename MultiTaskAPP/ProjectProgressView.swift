// ProjectProgressView.swift
import SwiftUI

struct ProjectProgressView: View {
    var tasks: [ProjectDetailTask]
    
    // 🎨 暖色調調色盤 (與 UserTasksView 保持一致)
    private let warmOrange = Color(red: 0.95, green: 0.48, blue: 0.12)     // 主色：溫暖深橘
    private let lightWarmOrange = Color(red: 1.0, green: 0.94, blue: 0.88) // 輔色：淺琥珀米色
    private let warmBackground = Color(red: 0.98, green: 0.97, blue: 0.95) // 背景：優雅暖白/燕麥色
    
    // 📊 統計數據計算
    private var totalTasksCount: Int {
        tasks.count
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var completionRate: Double {
        totalTasksCount > 0 ? Double(completedTasksCount) / Double(totalTasksCount) : 0.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("專案總進度")
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
                    // 底色軌道
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    // 進度軌道
                    Capsule()
                        .fill(warmOrange)
                        .frame(width: geo.size.width * completionRate, height: 8)
                        // 🌟 順滑的彈簧動畫，當任務勾選時會像流水一樣滑過去
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completionRate)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
        // 輕微的琥珀色陰影防壓迫
        .shadow(color: warmOrange.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(white: 0.95).ignoresSafeArea() // 給個淺灰底色方便看白底卡片
        ProjectProgressView(tasks: [
            ProjectDetailTask(id: "1", projectId: "p1", title: "任務一", assignee: "A", deadline: Date(), isCompleted: true),
            ProjectDetailTask(id: "2", projectId: "p1", title: "任務二", assignee: "B", deadline: Date(), isCompleted: false),
            ProjectDetailTask(id: "3", projectId: "p1", title: "任務三", assignee: "C", deadline: Date(), isCompleted: true)
        ])
        .padding()
    }
}
