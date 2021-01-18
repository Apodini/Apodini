import Foundation
import OpenCombine

/// Protocol that defines a visitor pattern for `ObservedObject`s.
public protocol ObservedObjectVisitor {
    /// Visits a concrete `ObservedObject`.
    func visit<Element>(_ observed: ObservedObject<Element>)
}

/// Implementation of an `ObservedObjectVisitor`.
/// Collects `Published` properties of `ObservedObject`s.
public class ObservedObjectModelBuilder: ObservedObjectVisitor {
    public var publishers: [AnyPublisher<Void, Never>]
    
    /// Creates an `ObservedObjectModelBuilder`.
    public init() {
        self.publishers = []
    }
    
    /// Collects every `Published` properties of `ObservedObject`s.
    public func visit<Element>(_ observed: ObservedObject<Element>) {
        for property in Mirror(reflecting: observed.wrappedValue).children {
            switch property.value {
            case let published as AnyPublished:
                publishers.append(published.publisher)
            default:
                continue
            }
        }
    }
}
