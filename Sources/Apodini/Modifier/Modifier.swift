//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


/// A modifier which can be invoked on a `Component`
public protocol Modifier: Component {
    associatedtype ModifiedComponent: Component
    typealias Content = Never
    
    var component: ModifiedComponent { get }
}

// Workaround for the "swift conditional conformance does not imply conformance to inherited protocol" compiler error
/// A modifier which can be invoked on a `Handler` or a `Component`
public typealias HandlerModifier = HandlerModifierProto & Handler & HandlerMetadataNamespace

/// A modifier which can be invoked on a `Handler` or a `Component`
public protocol HandlerModifierProto: Modifier, Handler where ModifiedComponent: Handler {
    associatedtype Response = ModifiedComponent.Response
    var component: ModifiedComponent { get }
}


public extension HandlerModifierProto {
    /// `HandlerModifier`s don't provide any further content
    /// - Note: this property should not be implemented in a modifier type
    var content: some Component { EmptyComponent() }
    
    /// `HandlerModifier`s don't implement the `handle` function
    /// - Note: this function should not be implemented in a modifier type
    func handle() -> Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}


// MARK: Metadata DSL
public extension Modifier {
    // At best, we would like to add something like `typealias Metadata = Never` to the Modifier protocol,
    // to prevent Metadata definitions for Modifiers altogether.
    // Problem really is the `HandlerModifier` protocol which conforms to Modifier AND Handler and thus
    // get an error like `error: 'Self.Metadata' cannot be equal to both 'HandlerMetadataCollection' and 'Never'`

    /// Modifiers can't expose any Metadata.
    var metadata: Metadata {
        fatalError("Metadata of a Modifier cannot be accessed!")
    }
}
