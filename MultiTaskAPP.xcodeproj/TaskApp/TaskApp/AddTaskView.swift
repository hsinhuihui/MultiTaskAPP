//
//  AddTaskView.swift
//  TaskApp
//
//  Created by 訪客使用者 on 2026/5/25.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var taskManager: TaskManager
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedAssignee: String = "未指定"

    @State private var showingAddMemberAlert = false
    @State private var newMemberName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任務基本資訊")) {
                    TextField("任務標題", text: $title)
                    TextField("詳細描述", text: $description)
                }
                
                Section(header: Text("時間與分配")) {
                    DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Picker("負責人", selection: $selectedAssignee) {
                            ForEach(taskManager.projectMembers, id: \.self) { member in
                                Text(member).tag(member)
                            }
                        }
                        
                        Button(action: { showingAddMemberAlert = true }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .navigationTitle("新增任務")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("儲存") {
                    taskManager.addTask(
                        title: title,
                        description: description,
                        dueDate: dueDate,
                        assignee: selectedAssignee
                    )
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
            .alert("新增專案成員", isPresented: $showingAddMemberAlert) {
                TextField("請輸入姓名", text: $newMemberName)
                Button("取消", role: .cancel) { newMemberName = "" }
                Button("新增") {
                    taskManager.addMember(newMemberName)
                    selectedAssignee = newMemberName 
                    newMemberName = ""
                }
            } message: {
                Text("輸入姓名後將會加入此專案的負責人名單中。")
            }
        }
    }
}
