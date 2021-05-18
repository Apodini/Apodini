//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

import Foundation

@dynamicMemberLookup
public struct Delegate<D> {
    
    var delegate: D
    
    var connection = Environment(\.connection)
    
    public init(_ delegate: D) {
        self.delegate = delegate
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<D, T>) -> T {
        delegate[keyPath: keyPath]
    }
    
    public func callAsFunction() throws -> D {
        try connection.wrappedValue.request.enterRequestContext(with: delegate) { _ in Void() }
        return delegate
    }
}
