//
//  CreateProjectView.swift
//  MultiTaskAPP
//

import SwiftUI

struct CreateProjectView: View {
    @State private var projectManager = ProjectManager()
    @State private var projectTitle: String = ""
    @State private var showInviteCode: String? = nil
    
    // 用於控制輸入框的焦點狀態
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            // 🌟 1. 柔和微光背景（適應深淺色模式）
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                
                // 🌟 2. 精緻標題區域
                VStack(spacing: 8) {
                    Text("建立新專案")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 30)
                    
                    Text("與你的組員一起高效協作任務")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // 🌟 3. 改良版卡片式輸入框
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
                
                // 🌟 4. 主動態按鈕（加入微縮小與漸層效果）
                Button(action: {
                    let trimmedTitle = projectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedTitle.isEmpty {
                        isInputFocused = false // 收起鍵盤
                        projectManager.createProject(title: trimmedTitle) { code in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showInviteCode = code
                                projectTitle = "" // 清空輸入框
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
                
                // 🌟 5. 當成功拿到邀請碼後，顯示的「極致質感邀請卡」
                if let code = showInviteCode {
                    VStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                            Text("專案建立成功！")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                        }
                        
                        Text("請複製下方邀請碼分享給你的組員：")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        // 亮橘色高級代碼顯示框
                        HStack {
                            Spacer()
                            Text(code)
                                .font(.system(size: 34, weight: .heavy, design: .monospaced))
                                .foregroundColor(.orange)
                            Spacer()
                            
                            // 額外附贈一個快捷複製的小按鈕，大幅優化體驗！
                            Button(action: {
                                UIPasteboard.general.string = code
                            }) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(10)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 70)
                        .background(Color.orange.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        )
                        .textSelection(.enabled) // 一樣保留長按複製功能
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
                
                Spacer()
            }
        }
        .animation(.snappy, value: isInputFocused) // 點擊輸入框時畫面有流暢的過渡
    }
}

// 預覽畫面
#Preview {
    CreateProjectView()
}
