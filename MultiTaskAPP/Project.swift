//
//  Project.swift
//  MultiTaskAPP
//
//  Created by 訪客使用者 on 2026/5/25.
//

import Foundation
import FirebaseFirestore


struct Project: Codable, Identifiable {
    @DocumentID var id: String?      // Firebase 會自動幫我們產生並帶入這個 Document ID
    var title: String                // 專案名稱
    var ownerId: String              // 建立者的 UID（用來控管權限，例如只有 owner 能刪除專案）
    var members: [String]            // 成員名單：包含所有加入成員的 UID 陣列
    var inviteCode: String           // 該專案專屬的 6 位數隨機邀請碼
}
