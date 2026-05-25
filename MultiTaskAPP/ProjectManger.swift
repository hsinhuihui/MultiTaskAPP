//
//  ProjectManger.swift
//  MultiTaskAPP
//
//  Created by 訪客使用者 on 2026/5/25.
//

import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseStorage
import FirebaseFirestore

class ProjectManager {
    
    // 產生 6 位數隨機邀請碼（大寫英文與數字組合）
    private func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map{ _ in letters.randomElement()! })
    }
    
    // 建立專案並存入 Firebase
    func createProject(title: String, completion: @escaping (String) -> Void) {
        // 1. 檢查目前有沒有使用者登入，拿到目前使用者的 UID
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 錯誤：尚未登入，無法建立專案")
            return
        }
        
        let newInviteCode = generateInviteCode()
        
        // 2. 封裝要上傳的專案資料
        let newProject = Project(
            title: title,
            ownerId: currentUser.uid,        // 擁有者是當前登入的人
            members: [currentUser.uid],       // 初始成員只有自己
            inviteCode: newInviteCode
        )
        
        // 3. 連線到 Firestore 並寫入 "projects" 集合中
        let db = Firestore.firestore()
        do {
            try db.collection("projects").addDocument(from: newProject)
            print("✅ 專案建立成功！雲端邀請碼為：\(newInviteCode)")
            
            // 4. 回傳邀請碼給前端畫面顯示
            completion(newInviteCode)
        } catch {
            print("❌ 建立專案失敗: \(error.localizedDescription)")
        }
    }
    //加入專案
    func joinProject(by inviteCode: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 1. 檢查當前使用者是否登入
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 錯誤：尚未登入，無法加入專案")
            return
        }
        
        let db = Firestore.firestore()
        
        // 2. 去資料庫搜尋哪一個專案的 inviteCode 符合使用者輸入的代碼
        db.collection("projects")
            .whereField("inviteCode", isEqualTo: inviteCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines))
            .getDocuments { querySnapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 3. 檢查有沒有找到對應的專案
                guard let document = querySnapshot?.documents.first else {
                    let noProjectError = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "找不到該邀請碼對應的專案，請檢查輸入是否正確。"])
                    completion(.failure(noProjectError))
                    return
                }
                
                // 4. 找到專案後，把目前使用者的 UID 塞進 members 陣列中
                let projectRef = document.reference
                projectRef.updateData([
                    "members": FieldValue.arrayUnion([currentUser.uid]) // 🌟 arrayUnion 可以確保 UID 不會重複加入
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // 成功加入，回傳專案名稱
                        let projectTitle = document.data()["title"] as? String ?? "未知專案"
                        completion(.success(projectTitle))
                    }
                }
            }
    }
    // 🌟 新增功能 A：上傳頭像到 Firebase Storage 并更新使用者資料
    func uploadAvatar(image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        // 定義在 Firebase 儲存的路径：avatars/使用者UID.jpg
        let storageRef = Storage.storage().reference().child("avatars/\(currentUser.uid).jpg")
        
        // 開始上傳
        storageRef.putData(imageData, metadata: nil as StorageMetadata?) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 上傳成功，取得圖片的下載網址 (URL)
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let downloadURL = url {
                    // 將這個網址寫入 Firebase Auth 的使用者個人檔案中
                    let changeRequest = currentUser.createProfileChangeRequest()
                    changeRequest.photoURL = downloadURL
                    changeRequest.commitChanges { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(downloadURL))
                        }
                    }
                }
            }
        }
    }

    // 🌟 新增功能 B：登出功能
    func signOut(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            print("❌ 登出失敗: \(error.localizedDescription)")
            completion(false)
        }
    }
}
