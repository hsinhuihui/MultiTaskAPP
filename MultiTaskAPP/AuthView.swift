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
    @State private var isUserLoggedIn = false
    
    // 輸入欄位的變數
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = "" // 註冊時用的暱稱
    
    // 錯誤訊息提示
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        if isUserLoggedIn {
            ProjectListView() // 登入成功就顯示專案大廳
        } else {
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
            }
            .onAppear {
                // 自動登入檢查：如果之前登入過，一開 App 就直接進大廳
                if Auth.auth().currentUser != nil {
                    isUserLoggedIn = true
                }
            }
        }
    }
    
    private func handleAuthAction() {
            errorMessage = ""
            if email.isEmpty || password.isEmpty { errorMessage = "請填寫所有欄位"; return }
            
            if isSignUpMode {
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error { self.errorMessage = error.localizedDescription; return }
                    
                    let changeRequest = authResult?.user.createProfileChangeRequest()
                    changeRequest?.displayName = self.displayName
                    changeRequest?.commitChanges { error in
                        print("註冊並登入成功：\(authResult?.user.email ?? "")")
                        
                        // 🌟 補上這行：通知最頂層「我註冊成功且登入了！」
                        NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), object: nil)
                    }
                }
            } else {
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error { self.errorMessage = error.localizedDescription; return }
                    print("登入成功：\(authResult?.user.email ?? "")")
                    
                    // 🌟 補上這行：通知最頂層「我登入成功了！」
                    NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), object: nil)
                }
            }
        }}

#Preview {
    AuthView()
}
