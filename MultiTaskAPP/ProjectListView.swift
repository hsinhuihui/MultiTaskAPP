//
//  ProjectListView.swift
//  MultiTaskAPP
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ProjectListView: View {
    @State private var projects: [Project] = []
    @State private var showCreateSheet = false
    
    // 👤 個人設定與狀態變數
    @State private var showProfileSheet = false
    @State private var userName: String = Auth.auth().currentUser?.displayName ?? "用戶"
    @State private var userEmail: String = Auth.auth().currentUser?.email ?? ""
    @State private var localImage: UIImage? = nil // 儲存手機剛選好的實體大頭貼圖片
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var inputName: String = "" // 暫存修改中的名字
    @State private var isEditingName = false // 控制名字旁邊小鉛筆的切換狀態
    
    // 6連格邀請碼彈窗狀態
    @State private var showCustomJoinAlert = false
    @State private var combinedPinValue: String = "" // 一把抓的 6 碼字串
    @FocusState private var isInputFocused: Bool // 控制隱形輸入框的焦點
    
    // 建立專案成功後的邀請碼彈窗狀態
    @State private var showCreateSuccessAlert = false
    @State private var createdProjectInviteCode = ""
    
    // 🌟 浮動通知（Toast）專用變數
    @State private var showToast = false
    @State private var toastMessage = ""
    
    let projectManager = ProjectManager()
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    // 🌟 柔和清爽的背景底色
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        // 垂直單列長條佈局
                        VStack(spacing: 14) {
                            
                            // 🌟 客製化高級頂部列 (頭像、問候語、輸入邀請碼)
                            HStack(spacing: 14) {
                                Button(action: {
                                    inputName = userName
                                    showProfileSheet = true
                                }) {
                                    if let img = localImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 42, height: 42)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 42, height: 42)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(userName) ")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    combinedPinValue = ""
                                    withAnimation { showCustomJoinAlert = true }
                                    isInputFocused = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "envelope.badge.fill")
                                        Text("輸入邀請碼")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.08))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 15)
                            .padding(.bottom, 5)
                            
                            // 🌟 橫向清爽扁平狀的「建立新專案」虛線按鈕
                            Button(action: { showCreateSheet = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.blue, Color(red: 0.2, green: 0.5, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                    
                                    Text("建立新專案...")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.blue.opacity(0.4))
                                }
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.01), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // 🌟 橫向清爽扁平長條狀的「專案列表」
                            ForEach(projects, id: \.inviteCode) { project in
                                HStack(spacing: 16) {
                                    
                                    // 左側：清新漸層圓圈與藍色資料夾
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                            .frame(width: 46, height: 46)
                                        
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    // 中間：專案名稱與跳轉頁面
                                    NavigationLink(destination: Text("這裡之後放 \(project.title) 的待辦事項")) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(project.title)
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(1)
                                            
                                            Text("查看專案詳細待辦任務")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 右側：亮橘色小巧複製邀請碼按鈕
                                    Button(action: {
                                        UIPasteboard.general.string = project.inviteCode
                                        triggerToast(message: "📋 已複製邀請碼：\(project.inviteCode)")
                                    }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "doc.on.doc.fill").font(.system(size: 9))
                                            Text(project.inviteCode)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        }
                                        .foregroundColor(.orange)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.orange.opacity(0.08))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black.opacity(0.03), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 3)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 30)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                .sheet(isPresented: $showCreateSheet, onDismiss: fetchProjects) {
                    // 🌟 100% 精準對齊你寫好的 CreateProjectView
                    CreateProjectView()
                }
                .sheet(isPresented: $showProfileSheet) {
                    profileSection
                        .presentationDetents([.fraction(0.5)])
                }
                .onAppear {
                    fetchProjects()
                    loadSavedAvatar()
                }
            }
            .disabled(showCustomJoinAlert || showCreateSuccessAlert)
            .blur(radius: (showCustomJoinAlert || showCreateSuccessAlert) ? 3 : 0)
            
            // ✉️ 6位數大寫邀請碼輸入彈窗
            if showCustomJoinAlert {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { withAnimation { showCustomJoinAlert = false } }
                VStack(spacing: 20) {
                    Text("輸入邀請碼").font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("請輸入組員提供的 6 位數大寫代碼").font(.footnote).foregroundColor(.gray)
                    
                    ZStack {
                        TextField("", text: $combinedPinValue)
                            .keyboardType(.asciiCapable)
                            .disableAutocorrection(true)
                            .focused($isInputFocused)
                            .opacity(0.01)
                            .frame(width: 1, height: 1)
                            .onChange(of: combinedPinValue) { _, newValue in
                                let upper = newValue.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                if upper.count > 6 { combinedPinValue = String(upper.prefix(6)) } else { combinedPinValue = upper }
                            }
                        
                        HStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { index in
                                let charString = getPinCharacter(at: index)
                                Text(charString)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 40, height: 50)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke((combinedPinValue.count == index && isInputFocused) ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
                                    )
                            }
                        }
                        .onTapGesture { isInputFocused = true }
                    }
                    .padding(.vertical, 10)
                    
                    HStack(spacing: 15) {
                        Button("取消") { withAnimation { showCustomJoinAlert = false } }.frame(maxWidth: .infinity).frame(height: 46).background(Color(.systemGray5)).foregroundColor(.primary).cornerRadius(12)
                        Button("確認加入") {
                            withAnimation { showCustomJoinAlert = false }
                            projectManager.joinProject(by: combinedPinValue) { result in
                                switch result {
                                case .success(let title):
                                    triggerToast(message: "🎉 成功加入專案：\(title)！")
                                    fetchProjects()
                                case .failure(let err):
                                    triggerToast(message: "❌ \(err.localizedDescription)")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 46).background(combinedPinValue.count < 6 ? Color.gray : Color.green).foregroundColor(.white).cornerRadius(12)
                        .disabled(combinedPinValue.count < 6)
                    }
                }
                .padding(24).background(Color(.systemBackground)).cornerRadius(24).shadow(color: Color.black.opacity(0.15), radius: 20).frame(maxWidth: 320)
            }
            
            // 🌟 底部浮動輕量通知 (Toast)
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 22)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
    
    // ⚙️ 核心修正：將 profileSection 移回正確的 struct 內部括號裡！
    var profileSection: some View {
        VStack(spacing: 20) {
            Text("個人設定")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
                .padding(.top)
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 8) {
                    if let img = localImage {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle()).shadow(radius: 4)
                    } else {
                        Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().frame(width: 80, height: 80).foregroundColor(.gray).clipShape(Circle())
                    }
                    Text("點擊更換照片").font(.system(size: 13, weight: .semibold)).foregroundColor(.blue)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        projectManager.uploadAvatarFree(image: image) { result in
                            switch result {
                            case .success:
                                self.localImage = image
                                triggerToast(message: "📸 成功更換手機相簿照片！")
                            case .failure(let err):
                                triggerToast(message: "❌ 更換失敗: \(err.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 12) {
                if isEditingName {
                    HStack(spacing: 10) {
                        TextField("輸入新暱稱", text: $inputName).textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !inputName.isEmpty {
                                projectManager.updateDisplayName(newName: inputName) { result in
                                    switch result {
                                    case .success:
                                        self.userName = inputName
                                        self.isEditingName = false
                                        triggerToast(message: "✅ 暱稱已成功修改！")
                                    case .failure(let err):
                                        triggerToast(message: "❌ 修改失敗: \(err.localizedDescription)")
                                    }
                                }
                            }
                        }) {
                            Text("儲存").font(.subheadline).bold().foregroundColor(.white).padding(.vertical, 8).padding(.horizontal, 12).background(inputName.isEmpty ? Color.gray : Color.blue).cornerRadius(8)
                        }
                        .disabled(inputName.isEmpty)
                        Button("取消") { withAnimation { isEditingName = false } }.font(.subheadline).foregroundColor(.gray)
                    }
                } else {
                    HStack(spacing: 8) {
                        Spacer()
                        Text(userName).font(.system(size: 20, weight: .bold, design: .rounded))
                        Button(action: { inputName = userName; withAnimation { isEditingName = true } }) {
                            Image(systemName: "pencil.line").font(.system(size: 16)).foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }
                Text(userEmail).font(.system(size: 13)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 25)
            
            Divider()
            
            Button(action: {
                projectManager.signOut { success in
                    if success {
                        showProfileSheet = false
                        NotificationCenter.default.post(name: NSNotification.Name("userLoggedOut"), object: nil)
                    }
                }
            }) {
                HStack { Image(systemName: "rectangle.portrait.and.arrow.right"); Text("登出帳號") }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 48).background(Color.red).cornerRadius(12).padding(.horizontal, 25)
            }
            Spacer()
        }
    }
    
    // 🛠️ 輔助函數群：獲取驗證碼字元
    private func getPinCharacter(at index: Int) -> String {
        let array = Array(combinedPinValue)
        if index < array.count { return String(array[index]) }
        return ""
    }
    
    // 🛠️ 輔助函數群：觸發吐司通知
    func triggerToast(message: String) {
        self.toastMessage = message
        withAnimation(.spring()) { self.showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { self.showToast = false }
        }
    }
    
    // 🛠️ 輔助函數群：從 Firebase 刷新專案列表
    func fetchProjects() {
        guard let currentUser = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("projects").whereField("members", arrayContains: currentUser.uid).getDocuments { querySnapshot, _ in
            if let docs = querySnapshot?.documents {
                DispatchQueue.main.async { self.projects = docs.compactMap { try? $0.data(as: Project.self) } }
            }
        }
    }
    
    // 🛠️ 輔助函數群：加載大頭貼
    func loadSavedAvatar() {
        guard let currentUser = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(currentUser.uid).getDocument { doc, _ in
            if let data = doc?.data(), let base64Str = data["avatarBase64"] as? String,
               let imageData = Data(base64Encoded: base64Str), let savedImage = UIImage(data: imageData) {
                DispatchQueue.main.async { self.localImage = savedImage }
            }
        }
    }
}

#Preview {
    ProjectListView()
}
