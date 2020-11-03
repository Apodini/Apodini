//
//  ContextKey.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

protocol ContextKey {
    associatedtype Value
    
    static var defaultValue: Self.Value { get }

    static func reduce(value: inout Self.Value,
                       nextValue: () -> Self.Value)
}
