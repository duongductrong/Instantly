//
//  Item.swift
//  Instantly
//
//  Created by duongductrong on 1/3/26.
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
