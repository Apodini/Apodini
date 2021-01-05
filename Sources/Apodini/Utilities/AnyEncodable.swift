//
//  AnyEncodable.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import Foundation


public struct AnyEncodable: Encodable {
    private let wrappedValue: Encodable
    
    
    init(_ wrappedValue: Encodable) {
        self.wrappedValue = wrappedValue
    }
    
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension AnyEncodable {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> T? {
        guard let anyEncoableWrappedValue = wrappedValue as? AnyEncodable else {
            return wrappedValue as? T
        }
        return anyEncoableWrappedValue.typed(T.self)
    }
}
