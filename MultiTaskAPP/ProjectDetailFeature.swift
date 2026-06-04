import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - 1. 獨立的任務資料模型 (維持原樣)
struct ProjectDetailTask: Identifiable, Codable {
    var id: String
    var projectId: String
    var title: String
    var assignee: String
    var deadline: Date
    var isCompleted: Bool
}

// MARK: - 2. 獨立的 ViewModel (已為你注入成員反查真實姓名邏輯)
class ProjectDetailViewModel: ObservableObject {
    @Published var tasks: [ProjectDetailTask] = []
    @Published var projectDeadline: Date? = nil
    @Published var projectMembers: [String] = []
    @Published var memberNames: [String: String] = [:] // 🌟 儲存 ["UID": "陳廷軒"] 的名冊字典

    private var db = Firestore.firestore()

    // 🌟 核心：拿抓到的成員 UID 陣列，去 users 集合反查名字
    func fetchMemberNames(uids: [String]) {
        let db = Firestore.firestore()
        for uid in uids {
            guard self.memberNames[uid] == nil else { continue } // 優化效能不重複抓
            
            db.collection("users").document(uid).getDocument { doc, _ in
                if let data = doc?.data(), let name = data["displayName"] as? String {
                    DispatchQueue.main.async {
                        self.memberNames[uid] = name // 對照成功
                    }
                } else {
                    if let data = doc?.data(), let email = data["email"] as? String {
                        DispatchQueue.main.async { self.memberNames[uid] = email }
                    }
                }
            }
        }
    }

    func fetchProjectDetails(projectId: String) {
        db.collection("projects").document(projectId).addSnapshotListener { snap, err in
            if let data = snap?.data() {
                if let timestamp = data["deadline"] as? Timestamp {
                    self.projectDeadline = timestamp.dateValue()
                }
                if let members = data["members"] as? [String] {
                    self.projectMembers = members
                    self.fetchMemberNames(uids: members) // 🌟 拿到成員UID後，立刻去後台偷抓真實名字
                }
            }
        }
    }

    func fetchTasks(projectId: String) {
        db.collection("project_tasks")
            .whereField("projectId", isEqualTo: projectId)
            .addSnapshotListener { snap, err in
                guard let docs = snap?.documents else { return }

                self.tasks = docs.compactMap { doc -> ProjectDetailTask? in
                    let data = doc.data()
                    let id = doc.documentID

                    guard let projId = data["projectId"] as? String,
                          let title = data["title"] as? String,
                          let assignee = data["assignee"] as? String,
                          let deadlineTimestamp = data["deadline"] as? Timestamp,
                          let isCompleted = data["isCompleted"] as? Bool else {
                        return nil
                    }

                    return ProjectDetailTask(
                        id: id,
                        projectId: projId,
                        title: title,
                        assignee: assignee,
                        deadline: deadlineTimestamp.dateValue(),
                        isCompleted: isCompleted
                    )
                }
                // 即時計算最新進度並直接同步回填至雲端專案文件
                self.updateProjectProgressInFirestore(projectId: projectId)
            }
    }
    
    // 輔助計算與上傳進度的方法
    private func updateProjectProgressInFirestore(projectId: String) {
        let totalTasks = self.tasks.count
        
        // 如果目前沒有任務，進度就是 0.0
        guard totalTasks > 0 else {
            db.collection("projects").document(projectId).updateData(["progress": 0.0])
            return
        }
        
        // 計算已完成的任務百分比
        let completedTasks = self.tasks.filter { $0.isCompleted }.count
        let calculatedProgress = Double(completedTasks) / Double(totalTasks)
        
        // 直接更新雲端該專案的 progress 欄位
        db.collection("projects").document(projectId).updateData([
            "progress": calculatedProgress
        ])
    }

    func addTask(projectId: String, title: String, assignee: String, deadline: Date) {
        let taskId = UUID().uuidString
        let taskData: [String: Any] = [
            "id": taskId,
            "projectId": projectId,
            "title": title,
            "assignee": assignee.isEmpty ? "未分配" : assignee,
            "deadline": Timestamp(date: deadline),
            "isCompleted": false
        ]
        db.collection("project_tasks").document(taskId).setData(taskData)
    }

    func updateTask(taskId: String, title: String, assignee: String, deadline: Date) {
        let updatedData: [String: Any] = [
            "title": title,
            "assignee": assignee.isEmpty ? "未分配" : assignee,
            "deadline": Timestamp(date: deadline)
        ]
        db.collection("project_tasks").document(taskId).updateData(updatedData)
    }

    func deleteTask(taskId: String) {
        db.collection("project_tasks").document(taskId).delete()
    }

    func deleteProject(projectId: String, completion: @escaping (Bool) -> Void) {
        db.collection("projects").document(projectId).delete { err in completion(err == nil) }
    }

    func leaveProject(projectId: String, currentUserEmail: String, completion: @escaping (Bool) -> Void) {
        db.collection("projects").document(projectId).updateData([
            "members": FieldValue.arrayRemove([currentUserEmail])
        ]) { err in completion(err == nil) }
    }

    func updateProjectDeadline(projectId: String, newDate: Date) {
        db.collection("projects").document(projectId).updateData(["deadline": Timestamp(date: newDate)])
    }
}

// MARK: - 3. 主要介面視圖
struct ProjectDetailFeatureView: View {
    var project: Project
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var viewModel = ProjectDetailViewModel()

    @State private var showingAddTask = false
    @State private var editingTask: ProjectDetailTask? = nil
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false
    @State private var showingDatePicker = false
    @State private var selectedProjectDate = Date()

    var body: some View {
        VStack(spacing: 16) {
            
            // 進度條
            ProjectProgressView(tasks: viewModel.tasks)
                            .padding(.horizontal)
                            .padding(.top, 10)
            
            List {
                Section(header: Text("專案資訊")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("名稱：\(project.title)").font(.title3).bold()
                        
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                            if let deadline = viewModel.projectDeadline {
                                HStack(spacing: 0) {
                                    Text("專案截止：")
                                    Text(deadline, style: .date)
                                }
                                .foregroundColor(deadline < Date() ? .red : .primary)
                            } else {
                                Text("專案截止：尚未設定").foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("設定日期") { showingDatePicker.toggle() }.font(.caption).buttonStyle(.bordered)
                        }
                        
                        if showingDatePicker {
                            DatePicker("選擇截止日期", selection: $selectedProjectDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .onChange(of: selectedProjectDate) { oldValue, newValue in
                                    viewModel.updateProjectDeadline(projectId: project.id ?? "", newDate: newValue)
                                    showingDatePicker = false
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("任務列表 (\(viewModel.tasks.count))")) {
                    if viewModel.tasks.isEmpty {
                        Text("目前沒有任務，請點擊右上角新增").foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.tasks) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title).font(.headline)
                                    HStack {
                                        Label(task.assignee.isEmpty ? "未分配" : task.assignee, systemImage: "person.crop.circle")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Label { Text(task.deadline, style: .date) } icon: { Image(systemName: "clock") }
                                            .foregroundColor(task.deadline < Date() ? .red : .secondary)
                                    }
                                    .font(.caption)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { viewModel.deleteTask(taskId: task.id) } label: { Label("刪除", systemImage: "trash") }
                                Button { editingTask = task } label: { Label("編輯", systemImage: "pencil") }.tint(.orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("專案詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddTask = true }) { Label("新增任務", systemImage: "plus.square") }
                    Divider()
                    Button(role: .destructive, action: { showingLeaveAlert = true }) { Label("退出專案", systemImage: "rectangle.portrait.and.arrow.right") }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) { Label("刪除專案", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .onAppear {
            let projId = project.id ?? ""
            viewModel.fetchProjectDetails(projectId: projId)
            viewModel.fetchTasks(projectId: projId)
        }
        // 🌟 串接：將當前的 viewModel 傳給新增視窗，使其共享真實姓名對照字典
        .sheet(isPresented: $showingAddTask) {
            ProjectAddTaskSheet(projectId: project.id ?? "", members: viewModel.projectMembers, viewModel: viewModel)
        }
        // 🌟 串接：將當前的 viewModel 傳給編輯視窗
        .sheet(item: $editingTask) { task in
            ProjectEditTaskSheet(task: task, members: viewModel.projectMembers, viewModel: viewModel)
        }
        .alert("確定要刪除專案嗎？", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                viewModel.deleteProject(projectId: project.id ?? "") { _ in presentationMode.wrappedValue.dismiss() }
            }
        } message: { Text("刪除後將無法復原，專案內的所有任務也會一併被刪除。") }
        .alert("確定要退出此專案嗎？", isPresented: $showingLeaveAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                let currentUserEmail = Auth.auth().currentUser?.email ?? "unknown"
                viewModel.leaveProject(projectId: project.id ?? "", currentUserEmail: currentUserEmail) { _ in presentationMode.wrappedValue.dismiss() }
            }
        } message: { Text("退出後您將無法再看到此專案的內容。") }
    }
}

// MARK: - 4. 新增任務表單 (已修正：完美解鎖真實名字)
struct ProjectAddTaskSheet: View {
    @Environment(\.presentationMode) var presentationMode
    var projectId: String
    var members: [String]
    @ObservedObject var viewModel: ProjectDetailViewModel // 改用 ObservedObject 共享數據

    @State private var title = ""
    @State private var assignee = ""
    @State private var deadline = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任務內容")) {
                    TextField("任務名稱 (ex. 畢業專題進度報告)", text: $title)
                    DatePicker("截止日期", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("分配任務負責人")) {
                    HStack {
                        Image(systemName: "person.badge.plus").foregroundColor(.gray)
                        TextField("直接輸入負責人姓名 (例如：陳廷軒)", text: $assignee)
                    }

                    if !members.isEmpty {
                        Picker("或從專案成員名單中選擇", selection: $assignee) {
                            Text("點擊挑選成員...").tag("")
                            ForEach(members, id: \.self) { uid in
                                // 🌟 專業修正點：透過字典把後台的 UID 轉成真實名字顯示在畫面上！
                                let realName = viewModel.memberNames[uid] ?? "載入名字中..."
                                Text(realName).tag(realName)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("新增專案任務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { presentationMode.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("發佈") {
                        viewModel.addTask(projectId: projectId, title: title, assignee: assignee, deadline: deadline)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 5. 編輯任務表單 (已修正：完美解鎖真實名字)
struct ProjectEditTaskSheet: View {
    @Environment(\.presentationMode) var presentationMode
    var task: ProjectDetailTask
    var members: [String]
    @ObservedObject var viewModel: ProjectDetailViewModel

    @State private var title = ""
    @State private var assignee = ""
    @State private var deadline = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任務內容")) {
                    TextField("任務名稱", text: $title)
                    DatePicker("截止日期", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("修改負責人")) {
                    HStack {
                        Image(systemName: "person.badge.plus").foregroundColor(.gray)
                        TextField("直接輸入負責人姓名", text: $assignee)
                    }

                    if !members.isEmpty {
                        Picker("或從專案成員名單中選擇", selection: $assignee) {
                            Text("點擊挑選成員...").tag("")
                            ForEach(members, id: \.self) { uid in
                                // 🌟 專業修正點：這裡同樣把 UID 改回顯示真實名字！
                                let realName = viewModel.memberNames[uid] ?? "載入名字中..."
                                Text(realName).tag(realName)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("編輯專案任務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { presentationMode.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        viewModel.updateTask(taskId: task.id, title: title, assignee: assignee, deadline: deadline)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                    .font(.headline)
                }
            }
            .onAppear {
                title = task.title
                assignee = task.assignee == "未分配" ? "" : task.assignee
                deadline = task.deadline
            }
        }
    }
}

// MARK: - 預覽畫面 (Preview)
#Preview {
    // 1. 建立一個假的專案資料供預覽使用
    let dummyProject = Project(
        id: "TEST_PROJECT_ID",
        title: "測試專案：iOS App 開發",
        ownerId: "USER_123",
        members: ["USER_123"],
        inviteCode: "123456"
    )
    
    // 2. 為了讓導覽列 (NavigationBar) 正常顯示，通常會在預覽時包一層 NavigationStack
    NavigationStack {
        ProjectDetailFeatureView(project: dummyProject)
    }
}
