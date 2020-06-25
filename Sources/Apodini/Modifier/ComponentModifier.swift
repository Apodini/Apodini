//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 6/24/20.
//

import Foundation

// Question: How does the typealias in `ViewModifier` public interface work? I don't see any public constraint to component to be View. Am I missing something? I could only model the behavioud with two associatedtypes.
protocol ComponentModifier {
    associatedtype ModifiedComponent: Component
    associatedtype Content: Component
    
    func modify(content: Self.ModifiedComponent) -> Self.Content
}

extension ComponentModifier where ModifiedComponent == Content {
    func body(content: Self.ModifiedComponent) -> Self.Content {
        content
    }
}

// Question: Is this how all modifiers are applied to Swift UI Views?
struct ModifiedComponent<Content, Modifier>: Component where Modifier: ComponentModifier, Modifier.Content == Content {
    let modifiedComponent: Modifier.ModifiedComponent
    let modifier: Modifier
    
    var content: Content {
        modifier.modify(content: modifiedComponent)
    }
}
