//
//  Item.swift
//  AppFace
//
//  Created by 魏平杰 on 2024/8/18.
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
