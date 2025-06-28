//
//  Item.swift
//  reeedy
//
//  Created by jonataswalker on 28/06/25.
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
