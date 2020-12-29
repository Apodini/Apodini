//
//  EndpointIdentifier.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-16.
//


@_implementationOnly import AssociatedTypeRequirementsVisitor


/// An `AnyEndpointIdentifier` object identifies an endpoint regardless of its specific type.
public class AnyEndpointIdentifier: RawRepresentable, Hashable, Equatable, CustomStringConvertible {
    public let rawValue: String
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public init<H: IdentifiableHandler>(_: H.Type) {
        self.rawValue = String(describing: H.self)
    }
    
    
    public var description: String {
        return "\(Self.self)(\"\(rawValue)\")"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    public static func == (lhs: AnyEndpointIdentifier, rhs: AnyEndpointIdentifier) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}


/// An endpoint identifier which is scoped to a specific endpoint type.
/// This is the primary way components should be identified and referenced.
public class ScopedEndpointIdentifier<H: IdentifiableHandler>: AnyEndpointIdentifier {
    public required init(rawValue: String) {
        super.init(rawValue: "\(H.self).\(rawValue)")
    }
    
    @available(*, unavailable, message: "'init(IdentifiableHandler.Type)' cannot be used with type-scoped endpoint identifiers")
    public override init<H: IdentifiableHandler>(_: H.Type) {
        fatalError("Not supported. Use one of the init(rawValue:) initializers.")
    }
}
