//
//  Text.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


public struct Text: _Component {
    private let text: String
    
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func handle() -> EventLoopFuture<String> {
        fatalError("Not implemented")
    }
}
