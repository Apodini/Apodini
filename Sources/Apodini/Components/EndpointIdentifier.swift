//
//  EndpointIdentifier.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-16.
//


@_implementationOnly import AssociatedTypeRequirementsVisitor


/// An `AnyEndpointIdentifier` object identifies an endpoint regardless of its specific type.
public class AnyEndpointIdentifier: RawRepresentable, Hashable, Equatable, CustomStringConvertible {
    public class var unspecified: AnyEndpointIdentifier { .init("<unspecified>") }
    
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
public class ScopedEndpointIdentifier<T: Handler>: AnyEndpointIdentifier {
    public override class var unspecified: ScopedEndpointIdentifier<T> { .init("<unspecified>") }
    
    public required init(rawValue: String) {
        super.init(rawValue: "\(T.self).\(rawValue)")
    }
    
    @available(*, unavailable, message: "'init(IdentifiableHandler.Type)' cannot be used with type-scoped endpoint identifiers")
    public override init<H: IdentifiableHandler>(_: H.Type) {
        fatalError("Not supported. Use one of the init(rawValue:) initializers.")
    }
}


// MARK: Utils


fileprivate protocol __EndpointComponentIdentifierGetterImplVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = __EndpointComponentIdentifierGetterImplVisitor
    associatedtype Input = IdentifiableHandler
    associatedtype Output
    func callAsFunction<T: IdentifiableHandler>(_ value: T) -> Output
}

fileprivate struct EndpointComponentIdentifierGetterImpl: __EndpointComponentIdentifierGetterImplVisitor {
    let visitorImpl: (AnyEndpointIdentifier) -> Void
    
    func callAsFunction<T: IdentifiableHandler>(_ value: T) {
        visitorImpl(value.endpointId)
    }
}


func LKTryToGetEndpointComponentIdentifier<C: IdentifiableHandler>(_ component: C) -> AnyEndpointIdentifier? {
    var endpointId: AnyEndpointIdentifier = .unspecified
    EndpointComponentIdentifierGetterImpl {
        endpointId = $0
    }(component)
    return endpointId
}
