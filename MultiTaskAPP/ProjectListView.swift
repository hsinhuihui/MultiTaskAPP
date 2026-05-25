import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ProjectListView: View {
    @State private var projects: [Project] = []
    @State private var showCreateSheet = false
    
    // 🌟 個人設定相關狀態
    @State private var showProfileSheet = false // 控制個人設定面板
    @State private var userName: String = Auth.auth().currentUser?.displayName ?? "用戶"
    @State private var userEmail: String = Auth.auth().currentUser?.email ?? ""
    @State private var avatarURL: URL? = Auth.auth().currentUser?.photoURL
    @State private var selectedItem: PhotosPickerItem? = nil // 相簿選擇器物件
    
    // 6連格邀請碼彈窗狀態
    @State private var showCustomJoinAlert = false
    @State private var pinValues: [String] = Array(repeating: "", count: 6)
    @FocusState private var activeField: Int?
    
    // 結果提示
    @State private var showResultAlert = false
    @State private var resultMessage = ""
    
    let projectManager = ProjectManager()
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        
                        // 建立新專案方形框
                        Button(action: { showCreateSheet = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill").font(.system(size: 35))
                                Text("建立新專案").font(.headline)
                            }
                            .frame(maxWidth: .infinity).frame(height: 140)
                            .background(Color(.systemGray6)).cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6])))
                        }
                        
                        // 顯示擁有專案
                        ForEach(projects) { project in
                            NavigationLink(destination: Text("這裡之後放 \(project.title) 的待辦事項")) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(project.title).font(.title3).bold().foregroundColor(.primary).multilineTextAlignment(.leading)
                                    Spacer()
                                    Text("邀請碼: \(project.inviteCode)").font(.caption).foregroundColor(.orange).bold()
                                }
                                .padding().frame(maxWidth: .infinity, alignment: .leading).frame(height: 140)
                                .background(Color(.secondarySystemBackground)).cornerRadius(15)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("我的專案大廳")
                .toolbar {
                    // 🌟 左上角：使用者頭像按鈕，點了開啟個人設定
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showProfileSheet = true }) {
                            AsyncImage(url: avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.crop.circle.fill").foregroundColor(.gray)
                            }
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 1))
                        }
                    }
                    
                    // 右上角：輸入邀請碼
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            pinValues = Array(repeating: "", count: 6)
                            withAnimation { showCustomJoinAlert = true }
                            activeField = 0
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.badge.fill")
                                Text("輸入邀請碼")
                            }
                            .font(.subheadline).bold()
                        }
                    }
                }
                .sheet(isPresented: $showCreateSheet, onDismiss: fetchProjects) {
                    CreateProjectView()
                }
                // 🌟 彈出個人設定視窗
                .sheet(isPresented: $showProfileSheet, onDismiss: {
                    // 重新去 Firebase 抓取最新更新好的頭像與暱稱
                    if let user = Auth.auth().currentUser {
                        self.avatarURL = user.photoURL
                        self.userName = user.displayName ?? "用戶"
                    }
                }) {
                    profileSection
                        .presentationDetents([.fraction(0.45)])
                }
                .alert("提示", isPresented: $showResultAlert) {
                    Button("確定", role: .cancel) { }
                } message: {
                    Text(resultMessage)
                }
                .onAppear { fetchProjects() }
            }
            .disabled(showCustomJoinAlert)
            .blur(radius: showCustomJoinAlert ? 3 : 0)
            
            // 6位數邀請碼彈窗 (維持原樣)
            if showCustomJoinAlert {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { withAnimation { showCustomJoinAlert = false } }
                VStack(spacing: 20) {
                    Text("輸入邀請碼").font(.title2).bold()
                    Text("請輸入組員提供的 6 位數大寫代碼").font(.footnote).foregroundColor(.gray)
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            TextField("", text: Binding(get: { pinValues[index] }, set: { handlePinInput(value: $0, index: index) }))
                            .font(.title.bold()).multilineTextAlignment(.center).frame(width: 40, height: 50)
                            .background(Color(.systemGray6)).cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeField == index ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2))
                            .keyboardType(.asciiCapable).focused($activeField, equals: index)
                        }
                    }
                    .padding(.vertical, 10)
                    HStack(spacing: 15) {
                        Button("取消") { withAnimation { showCustomJoinAlert = false } }.frame(maxWidth: .infinity).padding().background(Color(.systemGray5)).foregroundColor(.primary).cornerRadius(10)
                        Button("確認加入") {
                            let fullCode = pinValues.joined()
                            withAnimation { showCustomJoinAlert = false }
                            projectManager.joinProject(by: fullCode) { result in
                                switch result {
                                case .success(let title): resultMessage = "🎉 成功加入專案：\(title)！"; fetchProjects()
                                case .failure(let err): resultMessage = "❌ 加入失敗：\(err.localizedDescription)"
                                }
                                showResultAlert = true
                            }
                        }.frame(maxWidth: .infinity).padding().background(pinValues.joined().count < 6 ? Color.gray : Color.green).foregroundColor(.white).cornerRadius(10).disabled(pinValues.joined().count < 6)
                    }
                }.padding(25).background(Color(.systemBackground)).cornerRadius(20).shadow(radius: 20).frame(maxWidth: 320)
            }
        }
    }
    
    // 🌟 個人設定區的 UI 面板
    var profileSection: some View {
        VStack(spacing: 20) {
            Text("個人設定").font(.headline).foregroundColor(.gray).padding(.top)
            
            // 更換大頭貼區
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack {
                    AsyncImage(url: avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 80)).foregroundColor(.gray)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(radius: 4)
                    
                    Text("點擊更換照片").font(.caption).foregroundColor(.blue)
                }
            }
            // 監聽相簿選擇，選好立刻上傳
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        projectManager.uploadAvatar(image: image) { result in
                            if case .success(let url) = result {
                                self.avatarURL = url // 畫面即時更新頭像
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 5) {
                Text(userName).font(.title3).bold()
                Text(userEmail).font(.footnote).foregroundColor(.secondary)
            }
            
            Divider()
            
            // 登出按鈕
            Button(action: {
                projectManager.signOut { success in
                    if success {
                        showProfileSheet = false
                        
                        NotificationCenter.default.post(
                            name: NSNotification.Name("userLoggedOut"),
                            object: nil
                            )
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("登出帳號")
                    }
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            Spacer()
        }
    }
    
    // 處理 6 連格輸入
    private func handlePinInput(value: String, index: Int) {
        let upperValue = value.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if upperValue.isEmpty { pinValues[index] = ""; return }
        pinValues[index] = String(upperValue.last!)
        if index < 5 { activeField = index + 1 } else { activeField = nil }
    }
    
    // 撈取專案資料
    func fetchProjects() {
        guard let currentUser = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("projects").whereField("members", arrayContains: currentUser.uid).getDocuments { querySnapshot, _ in
            if let docs = querySnapshot?.documents {
                self.projects = docs.compactMap { try? $0.data(as: Project.self) }
            }
        }
    }
}
