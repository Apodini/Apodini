//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

import Foundation

//@dynamicMemberLookup
public struct Delegate<H: Handler> {
    
    var handler: H
    
    var connection = Environment(\.connection)
    
    public init(_ handler: H) {
        self.handler = handler
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<H, T>) -> T {
        handler[keyPath: keyPath]
    }
    
    public func evaluate() throws -> H.Response {
        return try connection.wrappedValue.request.enterRequestContext(with: handler) { handler in
            try handler.handle()
        }
    }
}
