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

