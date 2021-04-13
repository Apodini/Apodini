//
//  File.swift
//  
//
//  Created by Eldi Cano on 13.04.21.
//

import Foundation

/// A protocol that requires conformance to `Codable` and `Hashable` (also `Equatable`),
/// that most of the objects in `ApodiniDelta` conform to
protocol Value: Codable, Hashable {}

extension Value {
    /// Name of the type
    static var typeName: String { String(describing: Self.self) }
    
    /// The name of the type containing the name of the Module where it is defined to
    /// e.g. `Foundation.UUID`
    static var reflectingTypeName: String { String(reflecting: Self.self) }

    /// Object identifier of the type
    static var identifier: ObjectIdentifier { .init(Self.self) }
}
