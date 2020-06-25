//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 6/25/20.
//

import Foundation

struct Group<Content: Component>: Component {
    private let pathComponents: [PathComponent]
    let content: Content
    
    init(_ pathComponents: PathComponent...,
         @ComponentBuilder content: () -> Content) {
        self.pathComponents = pathComponents
        self.content = content()
    }
}
