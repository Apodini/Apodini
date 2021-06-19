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

/// Collects  every `ObservedObject` in the Handler.
func collectObservedObjects<E>(from element: E) -> [AnyObservedObject] {
    var observedObjects: [AnyObservedObject] = []
    
    execute({ observedObject in
        observedObjects.append(observedObject)
    }, on: element)
    
    return observedObjects
}

// MARK: Activatable
/// A function that prepares all contained properties (that have to be prepared)
/// for usage.
public func activate<Element>(_ subject: inout Element) {
    apply({ (activatable: inout Activatable) in
        activatable.activate()
    }, to: &subject)
}

// MARK: AnyParameter
func extractParameters<Element>(from subject: Element) -> [(String, AnyParameter)] {
    var result: [(String, AnyParameter)] = []
    
    execute({ (parameter: AnyParameter, label: String) in
        result.append((label, parameter))
    }, on: subject)
    
    return result
}

extension Apodini.Request {
    func enterRequestContext<E, R>(with element: E, executing method: (E) throws -> R) throws -> R {
        try inject(in: element)
        return try method(element)
    }
    
    fileprivate func inject<E>(in element: E) throws {
        // Inject all properties that can be injected using RequestInjectable
        
        try execute({ (requestInjectable: RequestInjectable) in
            try requestInjectable.inject(using: self)
        }, on: element)
    }
}

// MARK: ConnectionContext

extension Connection {
    func enterConnectionContext<E, R>(with element: E, executing method: (E) throws -> R) throws -> R {
        try request.inject(in: element)
        
        self.update(element)
        return try method(element)
    }
    
    private func update<E>(_ element: E) {
        execute({ (injectable: KeyPathInjectable) in
            injectable.inject(self, for: \Application.connection)
        }, on: element)
    }
}

// MARK: Dynamic Environment Value
extension Handler {
    func environment<K: EnvironmentAccessible, Value>(_ value: Value, for keyPath: WritableKeyPath<K, Value>) -> Self {
        var selfCopy = self

        apply({ (environment: inout Environment<K, Value>) in
            environment.prepareValue(value, for: keyPath)
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


// MARK: TypeInjectable
func injectAll<Element>(values: [Any], into subject: Element) {
    execute({ (injectable: TypeInjectable) in
        for value in values {
            injectable.inject(value)
        }
    }, on: subject)
}

// MARK: KeyPathInjectable
func injectAll<Element>(values: [AnyKeyPath: Any], into subject: Element) {
    execute({ (injectable: KeyPathInjectable) in
        for (keyPath, value) in values {
            injectable.inject(value, for: keyPath)
        }
    }, on: subject)
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
public func subscribe<Target>(on target: Target, using callback: @escaping ((AnyObservedObject, TriggerEvent) -> Void)) -> Observation? {
    var observation: Observation?
    execute({ (observedObject: AnyObservedObject) in
        observation = observedObject.register { triggerEvent in
            callback(observedObject, triggerEvent)
        }
    }, on: target)
    return observation
}


// MARK: Traversable

// The below code are to stay private except for prototyping purposes! This is intended to force
// common functionality to be declared inside this file, to make it available to the shared
// semantic model.


private protocol Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) throws -> Void, using names: [String]) rethrows
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) throws -> Void, using names: [String]) rethrows
}

private func execute<Element, Target>(
    _ operation: (Target, _ name: String) throws -> Void,
    on element: Element,
    using names: [String] = []) rethrows {
    if let traversable = element as? Traversable {
        try traversable.execute(operation, using: names)
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
            assert(((try? typeInfo(of: property.type).kind) ?? .none) != .class, "\(Target.self) \(property.name) on element \(info.name) must not be a class")
            
            try operation(target, (element as? DynamicProperty)?.namingStrategy(names + [property.name]) ?? property.name)
        case let dynamicProperty as DynamicProperty:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) != .class, "DynamicProperty \(property.name) on element \(info.name) must not be a class")

            try dynamicProperty.execute(operation, using: names + [property.name])
        case let traversables as Traversable:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) != .class, "Traversable \(property.name) on element \(info.name) must not be a class")
        
            try traversables.execute(operation, using: names + [property.name])
        default:
            break
        }
    }
}

/// Executes an operation to a target in an element.
private func execute<Element, Target>(_ operation: (Target) throws -> Void, on element: Element) rethrows {
    try execute({(target: Target, _: String) in
        try operation(target)
    },
    on: element,
    using: [])
}

private func apply<Element, Target>(
    _ mutation: (inout Target, _ name: String) throws -> Void,
    to element: inout Element,
    using names: [String] = []) rethrows {
    if var traversable = element as? Traversable {
        try traversable.apply(mutation, using: [])
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
            assert(((try? typeInfo(of: property.type).kind) ?? .none) != .class, "\(Target.self) \(property.name) on element \(info.name) must not be a class")
            
            try mutation(&target, (element as? DynamicProperty)?.namingStrategy(names + [property.name]) ?? property.name)
            let elem = element
            property.unsafeSet(
                value: target,
                on: &element,
                printing: "Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(elem) failed.")
        case var dynamicProperty as DynamicProperty:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) != .class, "DynamicProperty \(property.name) on element \(info.name) must not be a class")
            
            try dynamicProperty.apply(mutation, using: names + [property.name])
            let elem = element
            property.unsafeSet(
                value: dynamicProperty,
                on: &element,
                printing: "Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(elem) failed.")
        case var traversable as Traversable:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) != .class, "Traversable \(property.name) on element \(info.name) must not be a class")

            try traversable.apply(mutation, using: names + [property.name])
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
    },
    to: &element,
    using: [])
}


// MARK: DynamicProperty

private extension DynamicProperty {
    func execute<Target>(_ operation: (Target, _ name: String) throws -> Void, using names: [String]) rethrows {
        try Apodini.execute(operation, on: self, using: names)
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) throws -> Void, using names: [String]) rethrows {
        try Apodini.apply(mutation, to: &self, using: names)
    }
}

// MARK: Properties

extension Properties: Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) throws -> Void, using names: [String]) rethrows {
        for (name, element) in self {
            switch element {
            case let target as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Properties must not be a class")
                
                try operation(target, self.namingStrategy(names + [name]) ?? name)
            case let dynamicProperty as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Properties must not be a class")
                
                try dynamicProperty.execute(operation, using: names + [name])
            case let traversable as Traversable:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "Traversable \(name) on Properties must not be a class")
            
                try traversable.execute(operation, using: names + [name])
            default:
                break
            }
        }
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) throws -> Void, using names: [String]) rethrows {
        for (name, element) in self {
            switch element {
            case var target as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Properties must not be a class")
    
                try mutation(&target, self.namingStrategy(names + [name]) ?? name)
                self.elements[name] = target as? Property
            case var dynamicProperty as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Properties must not be a class")
                
                try dynamicProperty.apply(mutation, using: names + [name])
                self.elements[name] = dynamicProperty
            case var traversable as Traversable:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "Traversable \(name) on Properties must not be a class")
            
                try traversable.apply(mutation, using: names + [name])
                self.elements[name] = traversable as? Property
            default:
                break
            }
        }
    }
}

// MARK: Delegate

extension Delegate: Traversable {
    func execute<Target>(_ operation: (Target, String) throws -> Void, using names: [String]) rethrows {
        let delegate = storage?.value.delegate ?? delegateModel
        
        // we set the optionality of all delegated parameters according to the delegates optionality
        if Target.self == AnyParameter.self {
            try Apodini.execute({ (parameter: AnyParameter, name) throws in
                var parameter = parameter
                parameter.options.addOption(self.optionality, for: PropertyOptionKey.optionality)
                try operation(parameter as! Target, name)
            },
            on: delegate,
            using: names)
            return
        }

        try Apodini.execute(operation, on: delegate, using: names)
    }

    mutating func apply<Target>(_ mutation: (inout Target, String) throws -> Void, using names: [String]) rethrows {
        var delegate = storage?.value.delegate ?? delegateModel
        defer {
            if let storage = self.storage {
                storage.value.delegate = delegate
            } else {
                delegateModel = delegate
            }
        }
        
        // we set the optionality of all delegated parameters according to the delegates optionality
        if Target.self == AnyParameter.self {
            try Apodini.apply({ (parameter: inout AnyParameter, name) throws in
                parameter.options.addOption(self.optionality, for: PropertyOptionKey.optionality)
                var typedParameter = parameter as! Target
                try mutation(&typedParameter, name)
                parameter = typedParameter as! AnyParameter
            },
            to: &delegate,
            using: names)
            return
        }

        try Apodini.apply(mutation, to: &delegate, using: names)
    }
}


// MARK: Helpers

private extension Runtime.PropertyInfo {
    func unsafeSet<TObject>(value: Any, on object: inout TObject, printing errorMessage: @autoclosure () -> String) {
        do {
            try self.set(value: value, on: &object)
        } catch {
            fatalError(errorMessage())
        }
    }
}

#if DEBUG || RELEASE_TESTING
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
