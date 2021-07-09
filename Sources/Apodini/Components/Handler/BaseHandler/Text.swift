//
//  Text.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public struct Text: Handler {
    @Binding private var text: String
    
    public init(_ text: String) {
        self._text = .constant(text)
    }
    
    public func handle() -> String {
        text
    }
}
