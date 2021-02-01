//
//  Traversable.swift
//  
//
//  Created by Max Obermeier on 22.12.20.
//

import Foundation
import NIO
@_implementationOnly import Runtime

// MARK: ObservableObject

extension Handler {
    /// Collects  every `ObservedObject` in the Handler.
    func collectObservedObjects() -> [AnyObservedObject] {
        var observedObjects: [AnyObservedObject] = []
        
        execute({ observedObject in
            observedObjects.append(observedObject)
        }, on: self)
        
        return observedObjects
    }
}

// MARK: Activatable
/// A function that prepares all contained properties (that have to be prepared)
/// for usage.
public func activate<Element>(_ subject: inout Element) {
    apply({ (activatable: inout Activatable) in
        activatable.activate()
    }, to: &subject)
}

// MARK: RequestInjectable
func extractRequestInjectables<Element>(from subject: Element) -> [(String, RequestInjectable)] {
    var result: [(String, RequestInjectable)] = []
    
    execute({ (injectable: RequestInjectable, label: String) in
        result.append((label, injectable))
    }, on: subject)
    
    return result
}

extension Apodini.Request {
    func enterRequestContext<E, R>(with element: E, executing method: (E) -> EventLoopFuture<R>)
                   -> EventLoopFuture<R> {
        var element = element
        inject(in: &element)

        return method(element)
    }

    func enterRequestContext<E, R>(with element: E, executing method: (E) -> R) -> R {
        var element = element
        inject(in: &element)
        return method(element)
    }
    
    fileprivate func inject<E>(in element: inout E) {
        // Inject all properties that can be injected using RequestInjectable
        
        apply({ (requestInjectable: inout RequestInjectable) in
            requestInjectable.inject(using: self)
        }, to: &element)
    }
}

// MARK: ConnectionContext

extension Connection {
    func enterConnectionContext<E, R>(with element: E, executing method: (E) throws -> R) rethrows -> R {
        var element = element
        
        if let request = self.request {
            request.inject(in: &element)
        }
        
        self.update(&element)
        return try method(element)
    }
    
    private func update<E>(_ element: inout E) {
        apply({ (environment: inout Environment<Application, Connection>) in
            environment.setValue(self, for: \.connection)
        }, to: &element)
    }
}

// MARK: Dynamic Environment Value
extension Handler {
    func environment<K: EnvironmentAccessible, Value>(_ value: Value, for keyPath: WritableKeyPath<K, Value>) -> Self {
        var selfCopy = self

        apply({ (environment: inout Environment<K, Value>) in
            environment.setValue(value, for: keyPath)
        }, to: &selfCopy)
        
        return selfCopy
    }
}

// MARK: Application Injectable
extension Handler {
    func inject(app: Application) -> Self {
        var selfCopy = self
        
        Apodini.inject(app: app, to: &selfCopy)
    
        return selfCopy
    }
}

/// Injects an `Application` instance to a target.
public func inject<Element>(app: Application, to subject: inout Element) {
    apply({ (applicationInjectible: inout ApplicationInjectable) in
        applicationInjectible.inject(app: app)
    }, to: &subject)
}

// MARK: Property Check

/// Checks if an illegal element is used inside of a target.
public func check<Target, Value, E: Error>(on target: Target, for value: Value.Type, throw error: E) throws {
    try execute({ (_ : Value) in
        throw error
    }, on: target)
}

// MARK: ObservedObject

/// Subscribes to all `ObservedObject`s with a closure.
public func subscribe<Target>(on target: Target, using callback: @escaping ((AnyObservedObject) -> Void)) -> Observation? {
    var observation: Observation?
    execute({ (observedObject: AnyObservedObject) in
        observation = observedObject.register { callback(observedObject) }
    }, on: target)
    return observation
}


// MARK: Traversable

// The below code are to stay private except for prototyping purposes! This is intended to force
// common functionality to be declared inside this file, to make it available to the shared
// semantic model.


private protocol Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) throws -> Void) rethrows
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) throws -> Void) rethrows
}

private func execute<Element, Target>(_ operation: (Target, _ name: String) throws -> Void, on element: Element) rethrows {
    if let traversable = element as? Traversable {
        try traversable.execute(operation)
        return
    }
    
    guard let info = try? typeInfo(of: Element.self) else {
        fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
    }

    for property in info.properties {
        guard let child = try? property.get(from: element) else {
            fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
        }

        switch child {
        case let target as Target:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
            
            try operation(target, property.name)
        case let dynamicProperty as DynamicProperty:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")

            try dynamicProperty.execute(operation)
        case let traversables as Traversable:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Traversable \(property.name) on element \(info.name) must be a struct")
        
            try traversables.execute(operation)
        default:
            break
        }
    }
}

/// Executes an operation to a target in an element.
private func execute<Element, Target>(_ operation: (Target) throws -> Void, on element: Element) rethrows {
    try execute({(target: Target, _: String) in
        try operation(target)
    }, on: element)
}

private func apply<Element, Target>(_ mutation: (inout Target, _ name: String) throws -> Void, to element: inout Element) rethrows {
    if var traversable = element as? Traversable {
        try traversable.apply(mutation)
        // swiftlint:disable:next force_cast
        element = traversable as! Element
        return
    }
    
    guard let info = try? typeInfo(of: Element.self) else {
        fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
    }

    for property in info.properties {
        guard let child = try? property.get(from: element) else {
            fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
        }

        switch child {
        case var target as Target:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
            
            try mutation(&target, property.name)
            let elem = element
            property.unsafeSet(
                value: target,
                on: &element,
                printing: "Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(elem) failed.")
        case var dynamicProperty as DynamicProperty:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")
            
            try dynamicProperty.apply(mutation)
            let elem = element
            property.unsafeSet(
                value: dynamicProperty,
                on: &element,
                printing: "Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(elem) failed.")
        case var traversable as Traversable:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Traversable \(property.name) on element \(info.name) must be a struct")

            try traversable.apply(mutation)
            let elem = element
            property.unsafeSet(
                value: traversable,
                on: &element,
                printing: "Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(elem) failed.")
        default:
            break
        }
    }
}

/// Applies a mutation to an element.
private func apply<Element, Target>(_ mutation: (inout Target) throws -> Void, to element: inout Element) rethrows {
    try apply({(target: inout Target, _: String) in
        try mutation(&target)
    }, to: &element)
}

private extension DynamicProperty {
    func execute<Target>(_ operation: (Target, _ name: String) throws -> Void) rethrows {
        try Apodini.execute(operation, on: self)
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) throws -> Void) rethrows {
        try Apodini.apply(mutation, to: &self)
    }
}

extension Properties: Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) throws -> Void) rethrows {
        for (name, element) in self {
            switch element {
            case let target as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Properties must be a struct")
                
                try operation(target, name)
            case let dynamicProperty as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Properties must be a struct")
                
                try dynamicProperty.execute(operation)
            case let traversable as Traversable:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "Traversable \(name) on Properties must be a struct")
            
                try traversable.execute(operation)
            default:
                break
            }
        }
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) throws -> Void) rethrows {
        for (name, element) in self {
            switch element {
            case var target as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Properties must be a struct")
    
                try mutation(&target, name)
                self.elements[name] = target as? Property
            case var dynamicProperty as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Properties must be a struct")
                
                try dynamicProperty.apply(mutation)
                self.elements[name] = dynamicProperty
            case var traversable as Traversable:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "Traversable \(name) on Properties must be a struct")
            
                try traversable.apply(mutation)
                self.elements[name] = traversable as? Property
            default:
                break
            }
        }
    }
}

private extension Runtime.PropertyInfo {
    func unsafeSet<TObject>(value: Any, on object: inout TObject, printing errorMessage: @autoclosure () -> String) {
        do {
            try self.set(value: value, on: &object)
        } catch {
            fatalError(errorMessage())
        }
    }
}

#if DEBUG
    func exposedExecute<Element, Target>(_ operation: (Target, _ name: String) throws -> Void, on element: Element) rethrows {
        try execute(operation, on: element)
    }
    
    func exposedExecute<Element, Target>(_ operation: (Target) throws -> Void, on element: Element) rethrows {
        try execute(operation, on: element)
    }

    func exposedApply<Element, Target>(_ mutation: (inout Target, _ name: String) throws -> Void, to element: inout Element) rethrows {
        try apply(mutation, to: &element)
    }
    
    func exposedApply<Element, Target>(_ mutation: (inout Target) throws -> Void, to element: inout Element) rethrows {
        try apply(mutation, to: &element)
    }
#endif
