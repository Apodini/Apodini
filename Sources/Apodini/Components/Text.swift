//
//  Text.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


public struct Text: EndpointNode {
    private let text: String
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func handle() -> String {
        text
    }
}
