import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var isSignUpMode = false
    @State private var isUserLoggedIn = false
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var errorMessage = ""
    
    // 用於輸入框的動態焦點
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password
    }
    
    var body: some View {
        if isUserLoggedIn {
            ProjectListView() // 登入成功進入專案大廳
        } else {
            NavigationStack {
                ZStack {
                    // 🌟 1. 質感背景：極光深邃漸層
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.secondarySystemBackground), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // 🌟 2. 升級版：高質感幾何品牌 Logo 🌟
                        VStack(spacing: 15) {
                            ZStack {
                                // 後層的裝飾方塊
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 68, height: 68)
                                    .rotationEffect(.degrees(15))
                                
                                // 中層的裝飾方塊
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [.blue.opacity(0.2), .cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 68, height: 68)
                                    .rotationEffect(.degrees(-10))
                                
                                // 前層的核心圖示：多功能重疊卡片
                                Image(systemName: "rectangle.stack.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, Color(red: 0.4, green: 0.3, blue: 0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                
                                // 右上角的發光小星芒
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.orange)
                                    .offset(x: 26, y: -26)
                            }
                            .padding(.bottom, 10)
                            
                            Text(isSignUpMode ? "建立新帳號" : "歡迎回來")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Text(isSignUpMode ? "填寫以下資訊，開啟高效管理" : "請輸入您的帳號密碼繼續")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                        
                        // 🌟 3. 輸入框區塊（卡片式質感）
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
                        
                        // 🌟 4. 主動態按鈕
                        Button(action: handleAuthAction) {
                            Text(isSignUpMode ? "立即註冊" : "登入系統")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, Color(red: 0.3, green: 0.4, blue: 0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .buttonStyle(ScaleButtonStyle())
                        
                        // 🌟 5. 底部模式切換按鈕
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
                                    .foregroundColor(.blue)
                                    .bold()
                            }
                            .font(.system(size: 15))
                        }
                        .padding(.top, 5)
                        
                        Spacer()
                    }
                }
            }
            .onAppear {
                if Auth.auth().currentUser != nil {
                    isUserLoggedIn = true
                }
            }
        }
    }
    
    // 高質感自訂輸入框組件
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
                .foregroundColor(focusedField == field ? .blue : .gray)
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
                    color: focusedField == field ? Color.blue.opacity(0.1) : Color.black.opacity(0.03),
                    radius: focusedField == field ? 8 : 4,
                    x: 0,
                    y: focusedField == field ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focusedField == field ? .blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.snappy, value: focusedField)
    }
    
    // Firebase 登入註冊邏輯
    private func handleAuthAction() {
        errorMessage = ""
        if email.isEmpty || password.isEmpty { errorMessage = "請填寫所有欄位"; return }
        if isSignUpMode && displayName.isEmpty { errorMessage = "請輸入顯示名稱"; return }
        
        if isSignUpMode {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error { self.errorMessage = error.localizedDescription; return }
                
                let changeRequest = authResult?.user.createProfileChangeRequest()
                changeRequest?.displayName = self.displayName
                changeRequest?.commitChanges { error in
                    withAnimation { isUserLoggedIn = true }
                    NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), object: nil)
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error { self.errorMessage = error.localizedDescription; return }
                withAnimation { isUserLoggedIn = true }
                NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), object: nil)
            }
        }
    }
}

// 點擊按鈕時的彈性縮小效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    AuthView()
}
