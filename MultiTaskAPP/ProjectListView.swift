//
//  ProjectListView.swift
//  MultiTaskAPP
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ProjectListView: View {
    @Binding var isUserLoggedIn: Bool
    
    @State private var projects: [Project] = []
    
    // 👤 個人設定與狀態變數
    @State var showProfileSheet = false
    @State var userName: String = Auth.auth().currentUser?.displayName ?? "用戶"
    @State private var userEmail: String = Auth.auth().currentUser?.email ?? ""
    @State var localImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State var inputName: String = ""
    @State var isEditingName = false
    
    // ✉️「輸入邀請碼加入」彈窗狀態
    @State var showCustomJoinAlert = false
    @State var combinedPinValue: String = ""
    @FocusState var isInputFocused: Bool
    
    // 🌟 中央獨立建立專案小視窗控制狀態
    @State var showCreateProjectAlert = false
    @State var createPopupStage = 0
    @State var newProjectTitle = ""
    @State var generatedInviteCode = ""
    
    @State var showToast = false
    @State var toastMessage = ""
    
    @State private var taskManager = TaskManager()
    let projectManager = ProjectManager()
    
    // 🎨 完美對齊：導入 UserTasksView 的暖色調調色盤
    let themeOrange = Color(red: 0.95, green: 0.48, blue: 0.12)       // 主色：溫暖深橘
    let secondaryOrange = Color(red: 1.0, green: 0.58, blue: 0.25)
    let lightWarmOrange = Color(red: 1.0, green: 0.94, blue: 0.88)   // 輔色：淺琥珀米色
    let warmBackground = Color(red: 0.98, green: 0.97, blue: 0.95)   // 背景：優雅暖白/燕麥色
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 🏠 主體大廳畫面
                List {
                    // MARK: - 區塊一：頂部個人資料與邀請碼區
                    Section {
                        HStack(spacing: 14) {
                            Button(action: {
                                inputName = userName
                                showProfileSheet = true
                            }) {
                                HStack(spacing: 14) {
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
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("你好，\(userName) 👋")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
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
                                .background(lightWarmOrange)
                                .foregroundColor(themeOrange)
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    // MARK: - 區塊三：一格一格圓角卡片渲染區 📊
                    Section{
                        // 顯示擁有專案
                        ForEach(projects, id: \.inviteCode) { project in
                            ZStack {
                                // 1. 底層透明跳轉外殼 (流暢連線至你的真實新專案內頁)
                                NavigationLink {
                                    ProjectDetailFeatureView(project: project)
                                        .onDisappear {
                                            // 當使用者從內頁返回大廳時，大廳會立刻自動重新載入，讓剛改好的截止日期秒更新！
                                            fetchProjects()
                                        }
                                } label: {
                                    Color.clear
                                }
                                .opacity(0)
                                
                                // 2. 前台高級一格一格圓角卡片本體
                                VStack(spacing: 16) {
                                    // 【第一層：專案名稱 ＋ 右側複製邀請碼】
                                    HStack(alignment: .top) {
                                        Text(project.title)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // 📋 右上角精緻獨立複製按鈕 (採純手勢 onTapGesture，絕對不干擾卡片跳轉)
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc.fill").font(.system(size: 8))
                                            Text(project.inviteCode).font(.system(size: 10, weight: .bold, design: .monospaced))
                                        }
                                        .foregroundColor(themeOrange)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(lightWarmOrange)
                                        .cornerRadius(6)
                                        .onTapGesture {
                                            UIPasteboard.general.string = project.inviteCode
                                            triggerToast(message: "📋 已複製邀請碼：\(project.inviteCode)")
                                        }
                                    }
                                    
                                    // 【第二層：進度條 ＋ 右下角截止日期】
                                    HStack(alignment: .center, spacing: 20) {
                                        // 📊 左側橫向進度條
                                        VStack(alignment: .leading, spacing: 6) {
                                            let currentProgress = project.progress ?? 0.0
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.gray.opacity(0.1))
                                                        .frame(height: 6)
                                                    
                                                    Capsule()
                                                        .fill(LinearGradient(colors: [themeOrange, secondaryOrange], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: geo.size.width * CGFloat(currentProgress), height: 6)
                                                }
                                            }
                                            .frame(height: 6)
                                            
                                            Text("完成進度 \(Int(currentProgress * 100))%")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // 📅 右下角截止日期
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("截止日期")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                            
                                            // 🌟 專業修正點：在這裡呼叫下方寫好的轉換工具，即時呈現真實的專案截止日期！
                                            Text(formatProjectDeadline(project.deadline))
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundColor(project.deadline != nil && project.deadline! < Date() ? .red : .primary) // 貼心提醒：過期就自動亮紅字！
                                        }
                                    }
                                }
                                .padding(18)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: themeOrange.opacity(0.04), radius: 10, x: 0, y: 4)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(warmBackground)
                .blur(radius: (showCustomJoinAlert || showCreateProjectAlert) ? 3 : 0)
                
                // 遮罩背景層
                if showCustomJoinAlert || showCreateProjectAlert {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .zIndex(90)
                        .onTapGesture {
                            isInputFocused = false
                            withAnimation {
                                showCreateProjectAlert = false
                                showCustomJoinAlert = false
                            }
                        }
                }
                
                // 智慧 6 連格邀請碼小視窗
                if showCustomJoinAlert {
                    VStack(spacing: 24) {
                        HStack {
                            Spacer()
                            Text("輸入邀請碼").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.primary).padding(.leading, 24)
                            Spacer()
                            Button(action: { isInputFocused = false; withAnimation { showCustomJoinAlert = false } }) {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .padding(.bottom, -5)
                        
                        ZStack {
                            TextField("", text: $combinedPinValue).keyboardType(.asciiCapable).focused($isInputFocused).opacity(0.01).frame(width: 1, height: 1)
                                .onChange(of: combinedPinValue) { _, newValue in combinedPinValue = String(newValue.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).prefix(6)) }
                            HStack(spacing: 10) {
                                ForEach(0..<6, id: \.self) { index in
                                    let char = index < Array(combinedPinValue).count ? String(Array(combinedPinValue)[index]) : ""
                                    let isCurrent = index == combinedPinValue.count
                                    Text(char).font(.system(size: 22, weight: .bold, design: .monospaced)).frame(width: 40, height: 50).background(Color(.systemGray6)).cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke((isCurrent && isInputFocused) ? themeOrange : Color.clear, lineWidth: 1.5))
                                }
                            }.onTapGesture { isInputFocused = true }
                        }
                        .padding(.vertical, 10)
                        
                        Button(action: {
                            isInputFocused = false
                            withAnimation { showCustomJoinAlert = false }
                            projectManager.joinProject(by: combinedPinValue) { result in
                                switch result {
                                case .success(let title): triggerToast(message: "🎉 成功加入專案：\(title)！"); fetchProjects()
                                case .failure(let err): triggerToast(message: "❌ \(err.localizedDescription)")
                                }
                            }
                        }) {
                            Text("確認加入").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 48).background(combinedPinValue.count < 6 ? Color.gray.opacity(0.4) : themeOrange).cornerRadius(12)
                        }.disabled(combinedPinValue.count < 6)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.15), radius: 15)
                    .frame(maxWidth: 320)
                    .zIndex(100)
                }
                
                // 中央建立專案 A/B 面視窗
                if showCreateProjectAlert {
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            Button(action: { withAnimation(.easeOut(duration: 0.2)) { showCreateProjectAlert = false } }) {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(.gray.opacity(0.5))
                            }
                        }.padding(.bottom, -10)
                        
                        if createPopupStage == 0 {
                            VStack(spacing: 14) {
                                Text("建立新專案").font(.system(size: 20, weight: .bold, design: .rounded))
                                Text("與你的組員一起高效協作任務").font(.footnote).foregroundColor(.gray)
                                TextField("例如：畢業專題系統", text: $newProjectTitle).textFieldStyle(.roundedBorder).autocorrectionDisabled().padding(.horizontal, 4).padding(.top, 6)
                                Button(action: {
                                    let trimmed = newProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        projectManager.createProject(title: trimmed) { code in
                                            self.generatedInviteCode = code
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { self.createPopupStage = 1 }
                                            fetchProjects()
                                        }
                                    }
                                }) {
                                    Text("建立專案並產生邀請碼").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 46).background(newProjectTitle.isEmpty ? Color.gray.opacity(0.5) : themeOrange).cornerRadius(12)
                                }.disabled(newProjectTitle.isEmpty).padding(.top, 10)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.seal.fill").font(.system(size: 55)).foregroundColor(.green)
                                Text("已成功創建專案").font(.system(size: 19, weight: .bold, design: .rounded))
                                Text("快把下面的邀請碼分享給你的組員吧！").font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center)
                                HStack(spacing: 12) {
                                    Text(generatedInviteCode).font(.system(size: 22, weight: .heavy, design: .monospaced)).foregroundColor(.orange).padding(.horizontal, 12).frame(height: 50).background(Color.orange.opacity(0.06)).cornerRadius(12)
                                    Button(action: { UIPasteboard.general.string = generatedInviteCode; triggerToast(message: "📋 邀請碼已成功複製！") }) {
                                        HStack { Image(systemName: "doc.on.doc.fill"); Text("複製") }.font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white).padding(.horizontal, 14).frame(height: 50).background(themeOrange).cornerRadius(12)
                                    }
                                }.padding(.top, 5)
                            }
                        }
                    }.padding(24).background(Color(.systemBackground)).cornerRadius(24).shadow(color: Color.black.opacity(0.18), radius: 20).frame(maxWidth: 330).zIndex(100)
                }
                
                // 底部輕通知 Toast
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).padding(.vertical, 12).padding(.horizontal, 22).background(Color.black.opacity(0.85)).cornerRadius(25).padding(.bottom, 40)
                    }.transition(.move(edge: .bottom).combined(with: .opacity)).zIndex(999)
                }
            }
        }
        .onAppear {
            fetchProjects()
            loadSavedAvatar()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("openCreateProjectAlert"))) { _ in
            newProjectTitle = ""
            createPopupStage = 0
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showCreateProjectAlert = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("refreshProjects"))) { _ in
            fetchProjects()
        }
        .sheet(isPresented: $showProfileSheet) { profileSection.presentationDetents([.fraction(0.5)]) }
    }
    
    // 個人設定抽屜
    var profileSection: some View {
        VStack(spacing: 20) {
            Text("個人設定").font(.system(size: 16, weight: .bold)).foregroundColor(.gray).padding(.top)
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 8) {
                    if let img = localImage { Image(uiImage: img).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle()) }
                    else { Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().frame(width: 80, height: 80).foregroundColor(.gray) }
                    Text("點擊更換照片").font(.system(size: 13)).foregroundColor(.blue)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        projectManager.uploadAvatarFree(image: image) { result in
                            if case .success = result { self.localImage = image; triggerToast(message: "📸 成功更換照片！") }
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
                                    if case .success = result {
                                        self.userName = inputName
                                        self.isEditingName = false
                                        triggerToast(message: "✅ 暱稱與所有任務名稱已同步更新！")
                                    } else if case .failure(let err) = result {
                                        triggerToast(message: "❌ 更新失敗: \(err.localizedDescription)")
                                    }
                                }
                            }
                        }) { Text("儲存").font(.subheadline).bold().foregroundColor(.white).padding(.vertical, 8).padding(.horizontal, 12).background(Color.blue).cornerRadius(8) }
                        Button("取消") { withAnimation { isEditingName = false } }.font(.subheadline).foregroundColor(.gray)
                    }
                } else {
                    HStack(spacing: 8) {
                        Spacer(); Text(userName).font(.system(size: 20, weight: .bold))
                        Button(action: { inputName = userName; withAnimation { isEditingName = true } }) { Image(systemName: "pencil.line").font(.system(size: 16)).foregroundColor(.blue) }
                        Spacer()
                    }
                }
                Text(userEmail).font(.system(size: 13)).foregroundColor(.secondary)
            }.padding(.horizontal, 25)
            Divider()
            Button(action: {
                projectManager.signOut { success in
                    if success { showProfileSheet = false; isUserLoggedIn = false; NotificationCenter.default.post(name: NSNotification.Name("userLoggedOut"), object: nil) }
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("登出帳號")
                }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 48).background(Color.red).cornerRadius(12).padding(.horizontal, 25)
            }
            Spacer()
        }
    }
    
    // MARK: - 後台連線核心工具功能 & 🌟 新增：截止日期轉換格式化工具
    
    private func formatProjectDeadline(_ date: Date?) -> String {
        guard let actualDate = date else { return "尚未設定" }
        let formatter = DateFormatter()
        // 配合設計圖的高質感格式：例如 "10/26 11:30"
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: actualDate)
    }
    
    private func getPinCharacter(at index: Int) -> String {
        let array = Array(combinedPinValue)
        return index < array.count ? String(array[index]) : ""
    }
    
    func triggerToast(message: String) {
        self.toastMessage = message
        withAnimation(.spring()) { self.showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { self.showToast = false } }
    }
    
    func fetchProjects() {
        guard let currentUser = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("projects").whereField("members", arrayContains: currentUser.uid).getDocuments { querySnapshot, _ in
            if let docs = querySnapshot?.documents {
                DispatchQueue.main.async {
                    self.projects = docs.compactMap { try? $0.data(as: Project.self) }
                }
            }
        }
    }
    
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
