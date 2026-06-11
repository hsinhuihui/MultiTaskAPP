import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore

class ProjectManager {
    
    // 🧠 產生 6 位數隨機邀請碼
    private func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map{ _ in letters.randomElement()! })
    }
    
    // ➕ 建立專案
    func createProject(title: String, completion: @escaping (String) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 錯誤：尚未登入，無法建立專案")
            return
        }
        
        let newInviteCode = generateInviteCode()
        let newProject = Project(
            title: title,
            ownerId: currentUser.uid,
            members: [currentUser.uid],
            inviteCode: newInviteCode
        )
        
        let db = Firestore.firestore()
        do {
            try db.collection("projects").addDocument(from: newProject)
            print("✅ 專案建立成功！雲端邀請碼為：\(newInviteCode)")
            // 確保回傳在大廳的主執行緒，UI 動態才會順暢
            DispatchQueue.main.async {
                completion(newInviteCode)
            }
        } catch {
            print("❌ 建立專案失敗: \(error.localizedDescription)")
        }
    }
    
    // ✉️ 加入專案 (防重複加入高防呆版)
    func joinProject(by inviteCode: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 錯誤：尚未登入，無法加入專案")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("projects")
            .whereField("inviteCode", isEqualTo: inviteCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines))
            .getDocuments { querySnapshot, error in
                if let error = error {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    let noProjectError = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "找不到專案"])
                    DispatchQueue.main.async { completion(.failure(noProjectError)) }
                    return
                }
                
                // 🛑 核心改動：先檢查是不是早就已經加入過了
                let members = document.data()["members"] as? [String] ?? []
                if members.contains(currentUser.uid) {
                    let alreadyInError = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "您已加入此專案"])
                    DispatchQueue.main.async { completion(.failure(alreadyInError)) }
                    return
                }
                
                // 📝 沒加入過，才寫入雲端
                let projectRef = document.reference
                projectRef.updateData([
                    "members": FieldValue.arrayUnion([currentUser.uid])
                ]) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            let projectTitle = document.data()["title"] as? String ?? "未知專案"
                            completion(.success(projectTitle))
                        }
                    }
                }
            }
    }
    
    // 📸 免費手機大頭貼：上傳到 Firestore
    func uploadAvatarFree(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.1) else { return }
        let base64String = imageData.base64EncodedString()
        
        Firestore.firestore().collection("users").document(currentUser.uid).setData([
            "avatarBase64": base64String,
            "email": currentUser.email ?? ""
        ], merge: true) { error in
            // 🌟 修正完成：只負責標準回傳 success/failure，由大廳自己觸發通知
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateDisplayName(newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let uid = currentUser.uid
        let db = Firestore.firestore()
        
        // 1. 同步執行 Firestore 的更新 (users 文件 + 級聯更新任務名稱)
        let userRef = db.collection("users").document(uid)
        
        // 將兩個操作合併在一起處理
        let batch = db.batch()
        
        // A. 更新使用者暱稱
        batch.setData(["displayName": newName, "email": currentUser.email ?? ""], forDocument: userRef, merge: true)
        
        // B. 級聯更新：找到該使用者負責的所有任務，並更新 assignee 欄位
        // 注意：這需要事先讀取任務，我們改成先把查詢放在前面
        db.collection("project_tasks").whereField("assigneeId", isEqualTo: uid).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            for doc in snapshot?.documents ?? [] {
                batch.updateData(["assignee": newName], forDocument: doc.reference)
            }
            
            // 2. 提交 Batch
            batch.commit { batchError in
                if let batchError = batchError {
                    completion(.failure(batchError))
                    return
                }
                
                // 3. 最後才提交 Auth 的變更
                let changeRequest = currentUser.createProfileChangeRequest()
                changeRequest.displayName = newName
                changeRequest.commitChanges { authError in
                    if let authError = authError {
                        completion(.failure(authError))
                    } else {
                        print("🎉 暱稱成功同步至雲端與 Auth 設定檔")
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // 🛑 登出功能
    func signOut(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                completion(true)
            }
        } catch {
            print("❌ 登出失敗: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
