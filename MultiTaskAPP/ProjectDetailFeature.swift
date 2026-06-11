import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - 1. 任務資料模型
struct ProjectDetailTask: Identifiable, Codable {
    var id: String
    var projectId: String
    var title: String
    var assignee: String
    var deadline: Date
    var isCompleted: Bool
    var status: TaskStatus // 🌟 三段式狀態
}

// MARK: - 2. ViewModel
class ProjectDetailViewModel: ObservableObject {
    @Published var tasks: [ProjectDetailTask] = []
    @Published var projectDeadline: Date? = nil
    @Published var projectMembers: [String] = []
    @Published var memberNames: [String: String] = [:] // 🌟 ["UID": "真實名字"]

    private var db = Firestore.firestore()
    
    // 🌟 安全修正一：宣告監聽器變數，以便在離開視圖時徹底註銷
    private var projectListener: ListenerRegistration?
    private var tasksListener: ListenerRegistration?

    // 🌟 安全修正二：實作解構子 (deinit)
    // 當使用者「返回大廳」或離開此專案時，ViewModel 被釋放，這裡會主動登出雲端監聽，避免背景線程持續運作導致卡死！
    deinit {
        projectListener?.remove()
        tasksListener?.remove()
        print("🗑️ 記憶體安全釋放：ProjectDetailViewModel 順利銷毀，Firebase 監聽器已成功登出。")
    }

    // 🌟 安全修正三：在所有非同步閉包中使用 [weak self] 防止強引用循環
    func fetchMemberNames(uids: [String]) {
        for uid in uids {
            guard self.memberNames[uid] == nil else { continue }
            db.collection("users").document(uid).getDocument { [weak self] doc, _ in
                guard let self = self else { return }
                if let data = doc?.data(), let name = data["displayName"] as? String {
                    DispatchQueue.main.async { self.memberNames[uid] = name }
                } else if let data = doc?.data(), let email = data["email"] as? String {
                    DispatchQueue.main.async { self.memberNames[uid] = email }
                }
            }
        }
    }

    func fetchProjectDetails(projectId: String) {
        // 進入前先清理可能殘留的舊監聽器
        projectListener?.remove()
        
        projectListener = db.collection("projects").document(projectId)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 監聽專案詳情出錯: \(error.localizedDescription)")
                    return
                }
                
                if let data = snap?.data() {
                    DispatchQueue.main.async {
                        if let ts = data["deadline"] as? Timestamp {
                            self.projectDeadline = ts.dateValue()
                        }
                        if let members = data["members"] as? [String] {
                            self.projectMembers = members
                            self.fetchMemberNames(uids: members)
                        }
                    }
                }
            }
    }

    func fetchTasks(projectId: String) {
        // 進入前先清理可能殘留的舊監聽器
        tasksListener?.remove()
        
        tasksListener = db.collection("project_tasks")
            .whereField("projectId", isEqualTo: projectId)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 監聽任務出錯: \(error.localizedDescription)")
                    return
                }
                
                guard let docs = snap?.documents else { return }
                let parsedTasks = docs.compactMap { doc -> ProjectDetailTask? in
                    let data = doc.data()
                    guard let projId   = data["projectId"] as? String,
                          let title    = data["title"] as? String,
                          let assignee = data["assignee"] as? String,
                          let ts       = data["deadline"] as? Timestamp else { return nil }

                    let isCompleted = data["isCompleted"] as? Bool ?? false

                    // 🌟 優先讀取 status；舊資料用 isCompleted 推導
                    let status: TaskStatus
                    if let raw = data["status"] as? String,
                       let parsed = TaskStatus(rawValue: raw) {
                        status = parsed
                    } else {
                        status = isCompleted ? .done : .todo
                    }

                    return ProjectDetailTask(
                        id: doc.documentID,
                        projectId: projId,
                        title: title,
                        assignee: assignee,
                        deadline: ts.dateValue(),
                        isCompleted: isCompleted,
                        status: status
                    )
                }
                
                DispatchQueue.main.async {
                    self.tasks = parsedTasks
                    self.updateProjectProgressInFirestore(projectId: projectId)
                }
            }
    }

    private func updateProjectProgressInFirestore(projectId: String) {
        let total = self.tasks.count
        guard total > 0 else {
            db.collection("projects").document(projectId).updateData(["progress": 0.0])
            return
        }
        let completed = self.tasks.filter { $0.status == .done }.count
        db.collection("projects").document(projectId).updateData([
            "progress": Double(completed) / Double(total)
        ])
    }

    // 💡 1. 參數新增 projectName
    func addTask(projectId: String, projectName: String, title: String, assignee: String,
                 deadline: Date, status: TaskStatus = .todo) {
        // 🌟 獲取當前使用者的 UID，如果沒有登入則不執行
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 無法新增任務：未找到登入使用者")
            return
        }
    
        let taskId = UUID().uuidString
        let data: [String: Any] = [
            "id":          taskId,
            "projectId":   projectId,
            "title":       title,
            "assignee":    assignee.isEmpty ? "未分配" : assignee,
            "assigneeId":   uid, // 🌟 關鍵修正：寫入 UID，確保日後查詢穩定
            "deadline":    Timestamp(date: deadline),
            "isCompleted": status == .done,
            "status":      status.rawValue,
            "projectName": projectName // 💡 2. 使用傳進來的 projectName
        ]
        db.collection("project_tasks").document(taskId).setData(data) { error in
            if let error = error {
                print("❌ 新增任務失敗: \(error.localizedDescription)")
            } else {
                print("✅ 成功新增任務，並綁定 UID: \(uid)")
            }
        }
    }

    func updateTask(taskId: String, title: String, assignee: String,
                    deadline: Date, status: TaskStatus) {
        let data: [String: Any] = [
            "title":       title,
            "assignee":    assignee.isEmpty ? "未分配" : assignee,
            "deadline":    Timestamp(date: deadline),
            "isCompleted": status == .done,
            "status":      status.rawValue
        ]
        db.collection("project_tasks").document(taskId).updateData(data)
    }

    // 🌟 直接更新單一任務狀態
    func updateTaskStatus(taskId: String, newStatus: TaskStatus) {
        db.collection("project_tasks").document(taskId).updateData([
            "status":      newStatus.rawValue,
            "isCompleted": newStatus == .done
        ])
    }

    func deleteTask(taskId: String) {
        db.collection("project_tasks").document(taskId).delete()
    }

    // 🌟 修正：支援級聯刪除 (Cascade Delete) 的刪除專案功能
    func deleteProject(projectId: String, completion: @escaping (Bool) -> Void) {
        // 第一步：先找出專案底下所有相關的任務
        db.collection("project_tasks")
            .whereField("projectId", isEqualTo: projectId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 獲取專案關聯任務失敗: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // 建立 Firestore 批次操作 (Batch)
                let batch = self.db.batch()
                
                // 1. 將撈出來的所有專案任務加入批次刪除佇列
                if let documents = snapshot?.documents {
                    for doc in documents {
                        batch.deleteDocument(doc.reference)
                    }
                    print("🧹 已將 \(documents.count) 個關聯任務加入刪除佇列")
                }
                
                // 2. 將專案本體文件加入批次刪除佇列
                let projectRef = self.db.collection("projects").document(projectId)
                batch.deleteDocument(projectRef)
                
                // 3. 一次性打包提交 (Atomic Commit)
                batch.commit { batchError in
                    if let batchError = batchError {
                        print("❌ 批次級聯刪除失敗: \(batchError.localizedDescription)")
                        completion(false)
                    } else {
                        print("🗑️ 專案及底下所有任務已乾淨地一併刪除！")
                        completion(true)
                    }
                }
            }
    }

    func leaveProject(projectId: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(false); return }
        db.collection("projects").document(projectId).updateData([
            "members": FieldValue.arrayRemove([uid])
        ]) { err in completion(err == nil) }
    }

    func updateProjectDeadline(projectId: String, newDate: Date) {
        db.collection("projects").document(projectId).updateData([
            "deadline": Timestamp(date: newDate)
        ])
    }
}

// MARK: - 3. 主視圖
struct ProjectDetailFeatureView: View {
    var project: Project
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ProjectDetailViewModel()

    @State private var showingAddTask     = false
    @State private var editingTask: ProjectDetailTask? = nil
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert  = false
    @State private var showingDatePicker  = false
    @State private var selectedProjectDate = Date()

    private var todoTasks:       [ProjectDetailTask] { viewModel.tasks.filter { $0.status == .todo } }
    private var inProgressTasks: [ProjectDetailTask] { viewModel.tasks.filter { $0.status == .inProgress } }
    private var doneTasks:       [ProjectDetailTask] { viewModel.tasks.filter { $0.status == .done } }

    // 🎨 導入暖色調背景 (與大廳保持精緻一致的視覺感)
    private let warmBackground = Color(red: 0.98, green: 0.97, blue: 0.95)

    var body: some View {
        // 🌟 核心修正：移除外部 ZStack 與對應的 ignoresSafeArea 背景，改由 List 直接處理背景，徹底防範 SwiftUI 轉場凍結！
        List {
            // ── 頂部專案總進度卡片 ──
            Section {
                ProjectProgressView(tasks: viewModel.tasks)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
            }
            .listRowSeparator(.hidden)

            // ── 專案資訊 ──
            Section(header: Text("專案資訊")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("名稱：\(project.title)").font(.title3).bold()

                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        if let dl = viewModel.projectDeadline {
                            HStack(spacing: 0) {
                                Text("專案截止：")
                                Text(dl, style: .date)
                            }
                            .foregroundColor(dl < Date() ? .red : .primary)
                        } else {
                            Text("專案截止：尚未設定").foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("設定日期") { showingDatePicker.toggle() }
                            .font(.caption).buttonStyle(.bordered)
                    }

                    if showingDatePicker {
                        DatePicker("選擇截止日期", selection: $selectedProjectDate,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .onChange(of: selectedProjectDate) { _, new in
                                viewModel.updateProjectDeadline(projectId: project.id ?? "", newDate: new)
                                showingDatePicker = false
                            }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.white)

            // ── 待處理 ──
            Section(header: taskSectionHeader("待處理", count: todoTasks.count, color: .gray, showAdd: true)) {
                if todoTasks.isEmpty { emptyRow("沒有待處理任務") }
                else { ForEach(todoTasks) { taskRow($0) } }
            }
            .listRowBackground(Color.white)

            // ── 進行中 ──
            Section(header: taskSectionHeader("進行中", count: inProgressTasks.count, color: .orange)) {
                if inProgressTasks.isEmpty { emptyRow("沒有進行中任務") }
                else { ForEach(inProgressTasks) { taskRow($0) } }
            }
            .listRowBackground(Color.white)

            // ── 已完成 ──
            Section(header: taskSectionHeader("已完成", count: doneTasks.count, color: .green)) {
                if doneTasks.isEmpty { emptyRow("還沒有完成的任務") }
                else { ForEach(doneTasks) { taskRow($0) } }
            }
            .listRowBackground(Color.white)
        }
        .listStyle(.insetGrouped) // 使用內嵌群組樣式，視覺效果最乾淨
        .scrollContentBackground(.hidden) // 隱藏 iOS 16+ 預設的灰色 List 背景
        .background(warmBackground) // 🌟 直接在 List 套用背景，系統會自動流暢填充整塊安全區域，不衝突手勢！
        .navigationTitle("專案詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showingLeaveAlert = true }) {
                        Label("退出專案", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("刪除專案", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .onAppear {
            let id = project.id ?? ""
            viewModel.fetchProjectDetails(projectId: id)
            viewModel.fetchTasks(projectId: id)
        }
        .sheet(isPresented: $showingAddTask) {
            ProjectAddTaskSheet(projectId: project.id ?? "",
                                projectName: project.title,
                                members: viewModel.projectMembers,
                                viewModel: viewModel)
        }
        .sheet(item: $editingTask) { task in
            ProjectEditTaskSheet(task: task,
                                 members: viewModel.projectMembers,
                                 viewModel: viewModel)
        }
        .alert("確定要刪除專案嗎？", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                viewModel.deleteProject(projectId: project.id ?? "") { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: { Text("刪除後將無法復原，專案內的所有任務也會一併被刪除。") }
        .alert("確定要退出此專案嗎？", isPresented: $showingLeaveAlert) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                viewModel.leaveProject(projectId: project.id ?? "") { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: { Text("退出後您將無法再看到此專案的內容。") }
    }

    // MARK: - 任務列
    @ViewBuilder
    private func taskRow(_ task: ProjectDetailTask) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.status == .done, color: .gray)
                    .foregroundColor(task.status == .done ? .secondary : .primary)

                HStack {
                    Label(task.assignee.isEmpty ? "未分配" : task.assignee,
                          systemImage: "person.crop.circle")
                        .foregroundColor(.blue)
                    Spacer()
                    Label {
                        Text(task.deadline, style: .date)
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .foregroundColor(
                        task.deadline < Date() && task.status != .done ? .red : .secondary
                    )
                }
                .font(.caption)
            }

            // 🌟 狀態 Badge（點擊跳出選單直接選）
            Menu {
                Button { viewModel.updateTaskStatus(taskId: task.id, newStatus: .todo) }
                    label: { Label("待處理", systemImage: "circle") }
                Button { viewModel.updateTaskStatus(taskId: task.id, newStatus: .inProgress) }
                    label: { Label("進行中", systemImage: "clock.fill") }
                Button { viewModel.updateTaskStatus(taskId: task.id, newStatus: .done) }
                    label: { Label("已完成", systemImage: "checkmark.circle.fill") }
            } label: {
                statusBadge(task.status)
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.deleteTask(taskId: task.id)
            } label: { Label("刪除", systemImage: "trash") }

            Button { editingTask = task } label: {
                Label("編輯", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }

    // MARK: - UI 小元件
    @ViewBuilder
    private func statusBadge(_ status: TaskStatus) -> some View {
        Text(statusLabel(status))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .cornerRadius(8)
    }

    @ViewBuilder
    private func taskSectionHeader(_ title: String, count: Int, color: Color, showAdd: Bool = false) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(color.opacity(0.12))
                .foregroundColor(color)
                .cornerRadius(6)
            // 🌟 只在「待處理」顯示 + 按鈕
            if showAdd {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func emptyRow(_ text: String) -> some View {
        Text(text).foregroundColor(.secondary).font(.caption)
    }

    // MARK: - 輔助函式
    private func statusColor(_ s: TaskStatus) -> Color {
        switch s { case .todo: .gray; case .inProgress: .orange; case .done: .green }
    }
    private func statusLabel(_ s: TaskStatus) -> String {
        switch s { case .todo: "待處理"; case .inProgress: "進行中"; case .done: "已完成" }
    }
}

// MARK: - 4. 新增任務表單
struct ProjectAddTaskSheet: View {
    @Environment(\.presentationMode) var presentationMode
    var projectId: String
    var projectName: String
    var members: [String]
    @ObservedObject var viewModel: ProjectDetailViewModel

    @State private var title    = ""
    @State private var assignee = ""
    @State private var deadline = Date()
    @State private var status: TaskStatus = .todo

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任務內容")) {
                    TextField("任務名稱 (ex. 畢業專題進度報告)", text: $title)
                    DatePicker("截止日期", selection: $deadline,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("初始狀態")) {
                    Picker("狀態", selection: $status) {
                        Text("待處理").tag(TaskStatus.todo)
                        Text("進行中").tag(TaskStatus.inProgress)
                        Text("已完成").tag(TaskStatus.done)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("分配任務負責人")) {
                    HStack {
                        Image(systemName: "person.badge.plus").foregroundColor(.gray)
                        TextField("直接輸入負責人姓名", text: $assignee)
                    }
                    if !members.isEmpty {
                        Picker("或從專案成員名單中選擇", selection: $assignee) {
                            Text("點擊挑選成員...").tag("")
                            ForEach(members, id: \.self) { uid in
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("發佈") {
                        viewModel.addTask(projectId: projectId, projectName: projectName, title: title,
                                          assignee: assignee, deadline: deadline, status: status)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 5. 編輯任務表單
struct ProjectEditTaskSheet: View {
    @Environment(\.presentationMode) var presentationMode
    var task: ProjectDetailTask
    var members: [String]
    @ObservedObject var viewModel: ProjectDetailViewModel

    @State private var title    = ""
    @State private var assignee = ""
    @State private var deadline = Date()
    @State private var status: TaskStatus = .todo

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任務內容")) {
                    TextField("任務名稱", text: $title)
                    DatePicker("截止日期", selection: $deadline,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("任務狀態")) {
                    Picker("狀態", selection: $status) {
                        Text("待處理").tag(TaskStatus.todo)
                        Text("進行中").tag(TaskStatus.inProgress)
                        Text("已完成").tag(TaskStatus.done)
                    }
                    .pickerStyle(.segmented)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        viewModel.updateTask(taskId: task.id, title: title,
                                             assignee: assignee, deadline: deadline, status: status)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                    .font(.headline)
                }
            }
            .onAppear {
                title    = task.title
                assignee = task.assignee == "未分配" ? "" : task.assignee
                deadline = task.deadline
                status   = task.status
            }
        }
    }
}

// MARK: - 預覽
#Preview {
    let dummyProject = Project(
        id: "TEST_PROJECT_ID",
        title: "測試專案：iOS App 開發",
        ownerId: "USER_123",
        members: ["USER_123"],
        inviteCode: "123456"
    )
    NavigationStack {
        ProjectDetailFeatureView(project: dummyProject)
    }
}
