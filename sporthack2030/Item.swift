//
//  Item.swift
//  sporthack2030
//
//  Created by Ahmed on 18/09/1447 AH.
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
