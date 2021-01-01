//
//  Traversable.swift
//  
//
//  Created by Max Obermeier on 22.12.20.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import Runtime

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
                   throws -> EventLoopFuture<R> {
        var element = element
        try inject(in: &element)

        return method(element)
    }

    func enterRequestContext<E, R>(with element: E, executing method: (E) -> R) throws -> R {
        var element = element
        try inject(in: &element)
        return method(element)
    }
    
    private func inject<E>(in element: inout E) throws {
        // Inject all properties that can be injected using RequestInjectable
        
        try apply({ (requestInjectable: inout RequestInjectable) in
            try requestInjectable.inject(using: self)
        }, to: &element)
    }
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
            do {
                try property.set(value: target, on: &element)
            } catch {
                fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
            }
        case var dynamicProperty as DynamicProperty:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")
            try dynamicProperty.apply(mutation)
            do {
                try property.set(value: dynamicProperty, on: &element)
            } catch {
                fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
            }
        case var traversable as Traversable:
            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Traversable \(property.name) on element \(info.name) must be a struct")
        
            try traversable.apply(mutation)
            do {
                try property.set(value: traversable, on: &element)
            } catch {
                fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
            }
        default:
            break
        }
    }
}

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
