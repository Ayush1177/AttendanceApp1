//
//  Item.swift
//  AttendanceApp1
//
//  Created by Ayush on 27/02/25.
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
