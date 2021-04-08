//
//  Namespace.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//


/// A namespace which can be used with the Options API.
/// - Note: You cannot define any options directly within the outer namespace.
///         Instead, you define an inner namespace, which can then be used to define options.
/// The outer namespace allows using the Options API for different, unrelated, use cases, in a way
/// that mixing these unrelated options will result in a compile-time error.
/// - Note: Example: Let's say you have two places in your codebase where you want to use the Options API:
///         Specifying handler parameter options, and specifying deployment options.
///         There's two things now which are important to us:
///         - The user should not be able to pass a deployment option where a parameter option is expected
///           (because it would be unrelated, and couldn't be used in any meaningful way)
///         - We need to be able to differentiate between options based on who defined them
///           (ex: multiple deployment providers, each of which may define its own options.
///           They do not know of each other beforehand, and therefore cannot guarantee that there's no collisions.)
///         The outer namespace takes care of the first problem, by defining an "options domain" (eg: parameter options),
///         while the inner namespace addresses the second problem, by defining "sub-domains" within an outer namespace.
public protocol OuterNamespace {
    /// The identifier of this namespace
    static var identifier: String { get }
}


public protocol InnerNamespace {
    /// The outer namespace inside which this inner namespace resides
    associatedtype OuterNS: OuterNamespace
    
    /// The identifier of this inner namespace
    static var identifier: String { get }
}
