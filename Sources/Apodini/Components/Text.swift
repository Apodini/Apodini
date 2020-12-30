//
//  Text.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public struct Text: Handler {
    private let text: String
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func handle() -> String {
        text
    }
}
