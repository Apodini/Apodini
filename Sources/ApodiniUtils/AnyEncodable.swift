//
//  AnyEncodable.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import Foundation


public struct AnyEncodable: Encodable {
    public let wrappedValue: Encodable
    
    public init(_ wrappedValue: Encodable) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension AnyEncodable {
    public func typed<T: Encodable>(_ type: T.Type = T.self) -> T? {
        guard let anyEncodableWrappedValue = wrappedValue as? AnyEncodable else {
            return wrappedValue as? T
        }
        return anyEncodableWrappedValue.typed(T.self)
    }
}


extension Encodable {
    public func encodeToJSON() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
