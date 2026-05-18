//
//  AuthView.swift
//  MultiTaskAPP
//
//  Created by 訪客使用者 on 2026/5/18.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    // 控制目前是「登入」還是「註冊」狀態
    @State private var isSignUpMode = false
    
    // 輸入欄位的變數
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = "" // 註冊時用的暱稱
    
    // 錯誤訊息提示
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 標題
                Text(isSignUpMode ? "建立新帳號" : "歡迎回來")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)
                
                VStack(spacing: 15) {
                    // 如果是註冊模式，多填一個顯示名稱
                    if isSignUpMode {
                        TextField("顯示名稱 (暱稱)", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                    
                    TextField("電子郵件", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("密碼 (至少6碼)", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                .padding(.horizontal)
                
                // 錯誤訊息顯示
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
                
                // 主要動作按鈕（登入或註冊）
                Button(action: handleAuthAction) {
                    Text(isSignUpMode ? "註冊" : "登入")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 切換 登入/註冊 模式
                Button(action: {
                    withAnimation {
                        isSignUpMode.toggle()
                        errorMessage = "" // 切換時清空錯誤訊息
                    }
                }) {
                    Text(isSignUpMode ? "已經有帳號了？立即登入" : "還沒有帳號？立即註冊")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // 處理登入或註冊的邏輯
    private func handleAuthAction() {
        errorMessage = ""
        
        if email.isEmpty || password.isEmpty {
            errorMessage = "請填寫所有欄位"
            return
        }
        
        if isSignUpMode {
            // 執行 Firebase 註冊
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                // 註冊成功，順便設定使用者的 Display Name（顯示名稱）
                let changeRequest = authResult?.user.createProfileChangeRequest()
                changeRequest?.displayName = self.displayName
                changeRequest?.commitChanges { error in
                    if let error = error {
                        print("設定暱稱失敗: \(error.localizedDescription)")
                    }
                    print("註冊並登入成功：\(authResult?.user.email ?? "")")
                }
            }
        } else {
            // 執行 Firebase 登入
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                print("登入成功：\(authResult?.user.email ?? "")")
            }
        }
    }
}

#Preview {
    AuthView()
}
