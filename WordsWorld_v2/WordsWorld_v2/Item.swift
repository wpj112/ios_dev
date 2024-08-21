//
//  Item.swift
//  WordsWorld_v2
//
//  Created by 魏平杰 on 2024/8/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

// 模型结构
struct Word: Identifiable, Codable {
    var id = UUID()  // 自动生成 UUID
    var word: String
    var meaning: String
    var imageName: String
    
    // 自定义 Decodable 实现
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.word = try container.decode(String.self, forKey: .word)
        self.meaning = try container.decode(String.self, forKey: .meaning)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.id = UUID()  // 手动生成 UUID
    }
    
    // 默认初始化
    init(word: String, meaning: String, imageName: String) {
        self.word = word
        self.meaning = meaning
        self.imageName = imageName
    }
}

struct LearningSession: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var wordCount: Int
    var duration: Int
}

struct WordRecode: Identifiable, Codable {
    let id = UUID()
    let text: String
    var reviewCount: Int // 背诵次数
    var state: String //背诵状态
}
