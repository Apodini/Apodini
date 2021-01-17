import Foundation
import OpenCombine
@_implementationOnly import Runtime

public protocol AnySubscribingObject {
    func run()
}

public protocol ObservedObjectVisitor {
    func visit<Element>(_ observed: ObservedObject<Element>)
}

public class ObservedObjectModelBuilder: ObservedObjectVisitor {
    public var publishers: [AnyPublisher<Void, Never>]
    
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
