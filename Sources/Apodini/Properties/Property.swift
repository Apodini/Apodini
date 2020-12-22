//
//  Property.swift
//  
//
//  Created by Max Obermeier on 09.12.20.
//

import Foundation
@_implementationOnly import Runtime

/// This protocol is implemented by all of Apodini's property wrappers that are used access functionality or information
/// on a handling `Component`.
/// - Precondition: Only structs can be a `Property`
public protocol Property { }

/// `DynamicProperty` allows for wrapping `Property`s while maintianing their functionality. By conforming
/// a `struct` to `DynamicProperty` you make this `struct`'s properties discoverable to the Apodini
/// runtime framework. This can be used to e.g. combine two property wrappers provided by the Apodini framework
/// into one that merges their functionality
/// - Precondition: Only structs can be a `DynamicProperty`
public protocol DynamicProperty: Property { }


// MARK: Execute
func execute<Element, Target>(_ operation: (Target, _ name: String) -> Void, on element: Element) {
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

func execute<Element, Target>(_ operation: (Target) -> Void, on element: Element) {
    execute({(target: Target, _: String) in
        operation(target)
    }, on: element)
}

// MARK: Apply
func apply<Element, Target>(_ mutation: (inout Target, _ name: String) -> Void, to element: inout Element) {
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

func apply<Element, Target>(_ mutation: (inout Target) -> Void, to element: inout Element) {
    apply({(target: inout Target, _: String) in
        mutation(&target)
    }, to: &element)
}

// MARK: DynamicProperty Implementation
private extension DynamicProperty {
    func execute<Target>(_ operation: (Target, _ name: String) -> Void) {
        do {
            let info = try typeInfo(of: Self.self)

            for property in info.properties {
                let child = try property.get(from: self)

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
            fatalError("Executing operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on DynamicProperty \((try? typeInfo(of: Self.self))?.name ?? "Unknown Type") failed.")
        }
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> Void) {
        do {
            let info = try typeInfo(of: Self.self)

            for property in info.properties {
                let child = try property.get(from: self)

                switch child {
                case var target as Target:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                    
                    mutation(&target, property.name)
                    try property.set(value: target, on: &self)
                case var dynamicProperty as DynamicProperty:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")
                    
                    dynamicProperty.apply(mutation)
                    try property.set(value: dynamicProperty, on: &self)
                case var dynamics as Traversable:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Dynamics \(property.name) on element \(info.name) must be a struct")
                
                    dynamics.apply(mutation)
                    try property.set(value: dynamics, on: &self)
                default:
                    break
                }
            }
        } catch {
            fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on DynamicProperty \((try? typeInfo(of: Self.self))?.name ?? "Unknown Type") failed.")
        }
    }
}


// MARK: Properties Implemenation

private protocol Traversable {
    func execute<Target>(_ operation: (Target, _ name: String) -> Void)
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> Void)
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
