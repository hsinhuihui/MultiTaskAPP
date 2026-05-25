//
//  CreateProjectView.swift
//  MultiTaskAPP
//
//  Created by 訪客使用者 on 2026/5/25.
//

import SwiftUI

struct CreateProjectView: View {
    @State private var projectManager = ProjectManager()
    @State private var projectTitle: String = ""
    @State private var showInviteCode: String? = nil
    
    var body: some View {
        VStack(spacing: 25) {
            Text("建立新專案")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("專案名稱")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                TextField("專案名稱", text: $projectTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            .padding(.horizontal)
            
            Button(action: {
                if !projectTitle.isEmpty {
                    // 呼叫邏輯端開始建立專案
                    projectManager.createProject(title: projectTitle) { code in
                        // 成功後將產生的邀請碼記錄在狀態中以顯示於畫面
                        showInviteCode = code
                        projectTitle = "" // 清空輸入框
                    }
                }
            }) {
                Text("建立專案並產生邀請碼")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(projectTitle.isEmpty ? Color.gray : Color.blue) // 沒打字時變灰色
                    .cornerRadius(10)
            }
            .disabled(projectTitle.isEmpty) // 沒打字時禁用按鈕
            .padding(.horizontal)
            
            // 當成功拿到邀請碼後，顯示提示區塊
            if let code = showInviteCode {
                VStack(spacing: 12) {
                    Text("🎉 專案建立成功！")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                    
                    Text("請複製下方邀請碼分享給你的組員：")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(code)
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled) // 🌟 支援使用者長按複製
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

// 預覽畫面
#Preview {
    CreateProjectView()
}
