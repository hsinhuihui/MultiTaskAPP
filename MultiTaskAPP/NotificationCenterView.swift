//
//  NotificationCenterView.swift
//  MultiTaskAPP
//

import Foundation
import SwiftUI
import UserNotifications

struct NotificationCenterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notificationHistory: [UNNotification] = []
    
    // 💡 為了重新排程，我們需要抓取目前最新的任務數量
    @State private var taskManager = TaskManager()
    
    // 🌟 核心：連結 MainTabView 的手機儲存空間
    @AppStorage("dailyNotificationHour") private var savedHour = 8
    @AppStorage("dailyNotificationMinute") private var savedMinute = 30
    
    // 🌟 用來給 DatePicker 綁定的臨時 Date 變數
    @State private var selectedTime: Date = Date()
    
    let themeOrange = Color(red: 0.98, green: 0.45, blue: 0.15)
    let warmBackground = Color(red: 0.98, green: 0.97, blue: 0.95) // 燕麥暖色背景
    
    var body: some View {
        ZStack {
            // 🌟 1. 設定全域背景色
            warmBackground.ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    
                    // MARK: ── 🌟 新增：使用者自訂時間設定面板 ──
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "clock.badge.checkmark.fill")
                                .foregroundColor(themeOrange)
                                .font(.title3)
                            
                            Text("每日通知時間")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // 僅顯示時間（不顯示日期）的優雅選擇器
                            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                // 🌟 當使用者撥動時間時，立刻儲存並重新設定鬧鐘！
                                .onChange(of: selectedTime) { newTime in
                                    updateAndRescheduleNotification(with: newTime)
                                }
                        }
                        
                        Text("將在每天此時間檢查未完成任務，並對您發送進度通知。")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    
                    Divider()
                    
                    // MARK: ── 下方原本的通知歷史列表 ──
                    Group {
                        if notificationHistory.isEmpty {
                            VStack(spacing: 15) {
                                Spacer()
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("目前沒有收到任何通知提醒")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else {
                            List(notificationHistory, id: \.request.identifier) { notification in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(notification.request.content.title)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Text(formatDate(notification.date))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(notification.request.content.body)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(Color.white)
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden) // 💡 關鍵：隱藏 List 預設的白底
                            .background(Color.clear)          // 💡 關鍵：確保 List 背景透明
                        }
                    }
                }
                .navigationTitle("通知中心")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("關閉") {
                            dismiss()
                        }
                        .foregroundColor(themeOrange)
                    }
                }
                .onAppear {
                    // 1. 初始化 DatePicker 的時間為使用者上次儲存的時間
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    components.hour = savedHour
                    components.minute = savedMinute
                    self.selectedTime = Calendar.current.date(from: components) ?? Date()
                    
                    // 2. 啟動 Firebase 監聽，確保重新排程時能拿到精確的未完成任務數
                    taskManager.listenToUserTasks()
                    
                    // 3. 索取通知歷史紀錄
                    NotificationManager.shared.fetchDeliveredNotifications { fetchedList in
                        self.notificationHistory = fetchedList.sorted(by: { $0.date > $1.date })
                    }
                }
            }
        }
    }
    
    // MARK: - 🌟 新增：解析選中時間並重新排程
    private func updateAndRescheduleNotification(with date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let newHour = components.hour ?? 8
        let newMinute = components.minute ?? 30
        
        // 持久化儲存到手機
        self.savedHour = newHour
        self.savedMinute = newMinute
        
        // 算出當前未完成數，立刻呼叫排程更新鬧鐘！
        let incompleteCount = taskManager.tasks.filter { $0.status != .done }.count
        NotificationManager.shared.scheduleDailySummaryNotification(
            remainingTasksCount: incompleteCount,
            hour: newHour,
            minute: newMinute
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
