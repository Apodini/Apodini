//
//  File.swift
//  
//
//  Created by Eldi Cano on 29.03.21.
//

import Foundation

class PrimitiveValueWrapper<P: Primitive>: Value {
    let value: P

    init(_ value: P) {
        self.value = value
    }

    static func == (lhs: PrimitiveValueWrapper<P>, rhs: PrimitiveValueWrapper<P>) -> Bool {
        return lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
