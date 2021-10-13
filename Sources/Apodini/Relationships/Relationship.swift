//
// Created by Andreas Bauer on 16.01.21.
//

import Foundation

/// A instance of `Relationship` can be used to manually create
/// relationships between different `Handler`s.
///
/// Use the `Handler.relationship(to:)` modifier to specify the sources for the Relationship.
/// 
/// Use the `Handler.destination(of:)` modifier to specify the destination for the Relationship.
/// You can only define multiple destinations if the `Handler`s are located under the same path.
public struct Relationship: Decodable {
    internal let id = UUID()
    internal let name: String

    /// Initializes a new `Relationship` instance with a given name.
    /// The name MUST NOT equal to "self", which is a reserved relationship name.
    ///
    /// - Parameter name: The name for the relationship.
    public init(name: String) {
        precondition(name != "self", "The relationship name 'self' is reserved.")
        self.name = name
    }
}
