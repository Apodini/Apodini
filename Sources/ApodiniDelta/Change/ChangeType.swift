//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

/// Distinct change types that might occur
enum ChangeType: String, Value {
    case addition
    case removal
    case update
    case composite

    var description: String { rawValue }
}
