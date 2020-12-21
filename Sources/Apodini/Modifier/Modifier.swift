//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

protocol Modifier: Component {
    associatedtype ModifiedComponent: Component
    
    
    var component: Self.ModifiedComponent { get }
}


extension Modifier {
    /// A `Modifier`'s handle method should never be called!
    public func handle() -> Self.ModifiedComponent.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}
