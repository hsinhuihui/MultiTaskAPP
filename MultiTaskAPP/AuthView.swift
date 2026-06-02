//
//  AuthView.swift
//  MultiTaskAPP
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var isSignUpMode = false
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var errorMessage = ""
    
    // 用於輸入框的動態焦點
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password
    }
    
    // 主題暖橘色調
    let themeOrange = Color(red: 0.98, green: 0.45, blue: 0.15)
    let secondaryOrange = Color(red: 1.0, green: 0.58, blue: 0.25)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 輕奶油暖橘微光漸層背景
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.12), Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // 頂部向下挪動的間距
                        Spacer()
                            .frame(height: 70)
                        
                        // 幾何品牌 Logo 區域
                        VStack(spacing: 15) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [themeOrange.opacity(0.25), secondaryOrange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 68, height: 68)
                                    .rotationEffect(.degrees(15))
                                
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [secondaryOrange.opacity(0.2), Color.orange.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 68, height: 68)
                                    .rotationEffect(.degrees(-10))
                                
                                Image(systemName: "rectangle.stack.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [themeOrange, secondaryOrange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: themeOrange.opacity(0.3), radius: 5, x: 0, y: 3)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .offset(x: 26, y: -26)
                            }
                            .padding(.bottom, 10)
                            
                            Text(isSignUpMode ? "建立新帳號" : "歡迎回來")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(isSignUpMode ? "填寫以下資訊，開啟高效管理" : "請輸入您的帳號密碼繼續")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // 輸入框區塊
                        VStack(spacing: 16) {
                            if isSignUpMode {
                                customTextField(
                                    icon: "person.fill",
                                    placeholder: "顯示名稱 (暱稱)",
                                    text: $displayName,
                                    isSecure: false,
                                    field: .name
                                )
                            }
                            
                            customTextField(
                                icon: "envelope.fill",
                                placeholder: "電子郵件",
                                text: $email,
                                isSecure: false,
                                field: .email,
                                keyboardType: .emailAddress
                            )
                            
                            customTextField(
                                icon: "lock.fill",
                                placeholder: "密碼 (至少 6 碼)",
                                text: $password,
                                isSecure: true,
                                field: .password
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // 錯誤訊息提示
                        if !errorMessage.isEmpty {
                            HellenisticTransition()
                        }
                        
                        // 主動態登入按鈕
                        Button(action: handleAuthAction) {
                            Text(isSignUpMode ? "立即註冊" : "登入")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [themeOrange, secondaryOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: themeOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .buttonStyle(ScaleButtonStyle()) // 🌟 這裡會正常讀取下方的型別
                        
                        // 底部模式切換按鈕
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isSignUpMode.toggle()
                                errorMessage = ""
                            }
                        }) {
                            HStack(spacing: 5) {
                                Text(isSignUpMode ? "已經有帳號了？" : "還沒有帳號嗎？")
                                    .foregroundColor(.secondary)
                                Text(isSignUpMode ? "立即登入" : "免費註冊")
                                    .foregroundColor(themeOrange)
                                    .bold()
                            }
                            .font(.system(size: 15))
                        }
                        .padding(.top, 5)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func HellenisticTransition() -> some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(errorMessage)
        }
        .font(.footnote)
        .foregroundColor(.red)
        .padding(.horizontal, 25)
        .multilineTextAlignment(.center)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    @ViewBuilder
    private func customTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        field: Field,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(focusedField == field ? themeOrange : .gray)
                .frame(width: 24)
                .font(.system(size: 18))
                .animation(.snappy, value: focusedField)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .focused($focusedField, equals: field)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(
                    color: focusedField == field ? themeOrange.opacity(0.12) : Color.black.opacity(0.03),
                    radius: focusedField == field ? 8 : 4,
                    x: 0,
                    y: focusedField == field ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focusedField == field ? themeOrange.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.snappy, value: focusedField)
    }
    
    private func handleAuthAction() {
        errorMessage = ""
        if email.isEmpty || password.isEmpty { errorMessage = "請填寫所有欄位"; return }
        if isSignUpMode && displayName.isEmpty { errorMessage = "請輸入顯示名稱"; return }
        
        if isSignUpMode {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error { self.errorMessage = error.localizedDescription; return }
                    
                    let changeRequest = authResult?.user.createProfileChangeRequest()
                    changeRequest?.displayName = self.displayName
                    changeRequest?.commitChanges { error in
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), object: nil)
                        }
                    }
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error { self.errorMessage = error.localizedDescription; return }
                    NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), object: nil)
                }
            }
        }
    }
}
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
