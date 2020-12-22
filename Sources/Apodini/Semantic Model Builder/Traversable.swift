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
func extractRequestInjectables<Element>(from subject: Element) -> [String: RequestInjectable] {
    var result: [String: RequestInjectable] = [:]
    
    execute({ (injectable: RequestInjectable, label: String) in
        result[label] = injectable
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
    
    private func inject<E>(in element: inout E) {
        // Inject all properties that can be injected using RequestInjectable
        let elem = element
        
        apply({ (requestInjectable: inout RequestInjectable) in
            do {
                try requestInjectable.inject(using: self)
            } catch {
                fatalError("Injecting into element \(elem) failed.")
            }
        }, to: &element)
    }
}


// MARK: Traversable

// The below code are to stay private except for prototyping purposes! This is intended to force
// common functionality to be declared inside this file, to make it available to the shared
// semantic model.


private protocol Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) -> Void)
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> Void)
}

private func execute<Element, Target>(_ operation: (Target, _ name: String) -> Void, on element: Element) {
    if let traversable = element as? Traversable {
        traversable.execute(operation)
        return
    }
    
    do {
        let info = try typeInfo(of: Element.self)

        for property in info.properties {
            let child = try property.get(from: element)

            switch child {
            case let target as Target:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                
                operation(target, property.name)
            case let dynamicProperty as DynamicProperty:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")

                dynamicProperty.execute(operation)
            case let dynamics as Traversable:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Dynamics \(property.name) on element \(info.name) must be a struct")
            
                dynamics.execute(operation)
            default:
                break
            }
        }
    } catch {
        fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
    }
}

private func execute<Element, Target>(_ operation: (Target) -> Void, on element: Element) {
    execute({(target: Target, _: String) in
        operation(target)
    }, on: element)
}

private func apply<Element, Target>(_ mutation: (inout Target, _ name: String) -> Void, to element: inout Element) {
    if var traversable = element as? Traversable {
        traversable.apply(mutation)
        // swiftlint:disable:next force_cast
        element = traversable as! Element
        return
    }
    do {
        let info = try typeInfo(of: Element.self)

        for property in info.properties {
            let child = try property.get(from: element)

            switch child {
            case var target as Target:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                
                mutation(&target, property.name)
                try property.set(value: target, on: &element)
            case var dynamicProperty as DynamicProperty:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")
                dynamicProperty.apply(mutation)
                try property.set(value: dynamicProperty, on: &element)
            case var dynamics as Traversable:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Dynamics \(property.name) on element \(info.name) must be a struct")
            
                dynamics.apply(mutation)
                try property.set(value: dynamics, on: &element)
            default:
                break
            }
        }
    } catch {
        fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
    }
}

private func apply<Element, Target>(_ mutation: (inout Target) -> Void, to element: inout Element) {
    apply({(target: inout Target, _: String) in
        mutation(&target)
    }, to: &element)
}

private extension DynamicProperty {
    func execute<Target>(_ operation: (Target, _ name: String) -> Void) {
        Apodini.execute(operation, on: self)
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> Void) {
        Apodini.apply(mutation, to: &self)
    }
}

extension Properties: Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) -> Void) {
        for (name, element) in self {
            switch element {
            case let target as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Properties must be a struct")
                
                operation(target, name)
            case let dynamicProperty as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Properties must be a struct")
                
                dynamicProperty.execute(operation)
            case let dynamics as Traversable:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "Properties \(name) on Properties must be a struct")
            
                dynamics.execute(operation)
            default:
                break
            }
        }
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> Void) {
        for (name, element) in self {
            switch element {
            case var target as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Properties must be a struct")
    
                mutation(&target, name)
                // swiftlint:disable:next force_cast
                self.elements[name] = (target as! Element)
            case var dynamicProperty as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Properties must be a struct")
                
                dynamicProperty.apply(mutation)
                // swiftlint:disable:next force_cast
                self.elements[name] = (dynamicProperty as! Element)
            case var dynamics as Traversable:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "Properties \(name) on Properties must be a struct")
            
                dynamics.apply(mutation)
                // swiftlint:disable:next force_cast
                self.elements[name] = (dynamics as! Element)
            default:
                break
            }
        }
    }
}

#if DEBUG
    public func exposedExecute<Element, Target>(_ operation: (Target, _ name: String) -> Void, on element: Element) {
        execute(operation, on: element)
    }
    
    public func exposedExecute<Element, Target>(_ operation: (Target) -> Void, on element: Element) {
        execute(operation, on: element)
    }

    public func exposedApply<Element, Target>(_ mutation: (inout Target, _ name: String) -> Void, to element: inout Element) {
        apply(mutation, to: &element)
    }
    
    public func exposedApply<Element, Target>(_ mutation: (inout Target) -> Void, to element: inout Element) {
        apply(mutation, to: &element)
    }
#endif
