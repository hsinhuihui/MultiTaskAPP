//
//  CreateProjectView.swift
//  MultiTaskAPP
//

import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss // 🌟 負責控制自己關閉的變數
    @State private var projectManager = ProjectManager()
    @State private var projectTitle: String = ""
    
    // 🌟 定義一個接頭，當成功時把邀請碼丟回給大廳
    var onSuccess: (String) -> Void
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // 標題區域
                VStack(spacing: 8) {
                    Text("建立新專案")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 40)
                    
                    Text("與你的組員一起高效協作任務")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // 卡片式輸入框
                VStack(alignment: .leading, spacing: 10) {
                    Text("專案名稱")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(isInputFocused ? .blue : .gray)
                            .font(.system(size: 18))
                        
                        TextField("例如：畢業專題系統", text: $projectTitle)
                            .focused($isInputFocused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isInputFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 20)
                
                // 主按鈕
                Button(action: {
                    let trimmedTitle = projectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedTitle.isEmpty {
                        isInputFocused = false
                        projectManager.createProject(title: trimmedTitle) { code in
                            // 🌟 核心邏輯：先關掉自己這個頁面！
                            dismiss()
                            
                            // 🌟 延遲一下下，等頁面滑下去後，通知大廳跳出邀請碼大卡片！
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSuccess(code)
                            }
                        }
                    }
                }) {
                    Text("建立專案並產生邀請碼")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            projectTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            LinearGradient(colors: [Color.gray.opacity(0.6)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.blue, Color(red: 0.2, green: 0.5, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: projectTitle.isEmpty ? .clear : Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .disabled(projectTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .animation(.snappy, value: isInputFocused)
    }
}

// 預覽畫面（補上範例接頭讓預覽不報錯）
#Preview {
    CreateProjectView(onSuccess: { _ in })
}
