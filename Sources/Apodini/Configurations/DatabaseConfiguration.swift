//
//  File.swift
//  
//
//  Created by Felix Desiderato on 21.11.20.
//

import Vapor
import Fluent

public struct DatabaseConfiguration: Configuration {
    
    private let text: String
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func configure() -> String {
        print(text)
        return text
    }
    
}
