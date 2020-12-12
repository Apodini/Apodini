//
//  DynamicProperty.swift
//  
//
//  Created by Max Obermeier on 09.12.20.
//

import Foundation
import Runtime

/// DynamicProperty allows for wrapping Apodini's property wrappers while maintianing their functionality.
/// - Precondition: Only structs can be a DynamicProperty
public protocol DynamicProperty { }




// MARK: Execute
func execute<Element, Target>(_ operation: (Target, _ name: String) -> (), on element: Element) {
    do {
        let info = try typeInfo(of: Element.self)

        for property in info.properties {
            let child = try property.get(from: element)

            switch child {
            case let t as Target:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                
                operation(t, property.name)
            case let dp as DynamicProperty:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")

                dp.execute(operation)
            case let dyn as Dynamics:
                // no assertion needed because Dynamics is defined by Apodini
            
                dyn.execute(operation)
            default:
                break;
            }
        }
    } catch {
        fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
    }
}

func execute<Element, Target>(_ operation: (Target) -> (), on element: Element) {
    execute({(t: Target, name: String) in
        operation(t)
    }, on: element)
}

// MARK: Apply
func apply<Element, Target>(_ mutation: (inout Target, _ name: String) -> (), to element: inout Element) {
    do {
        
        
        let info = try typeInfo(of: Element.self)

        for property in info.properties {
            let child = try property.get(from: element)

            switch child {
            case var t as Target:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                
                mutation(&t, property.name)
                try property.set(value: t, on: &element)
            case var dp as DynamicProperty:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")
                dp.apply(mutation)
                try property.set(value: dp, on: &element)
            case var dyn as Dynamics:
                // no assertion needed because Dynamics is defined by Apodini
            
                dyn.apply(mutation)
                try property.set(value: dyn, on: &element)
            default:
                break;
            }
        }
    } catch {
        fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on element \(element) failed.")
    }
}

func apply<Element, Target>(_ mutation: (inout Target) -> (), to element: inout Element) {
    apply({(t: inout Target, name: String) in
        mutation(&t)
    }, to: &element)
}


// MARK: DynamicProperty Implementation
fileprivate extension DynamicProperty {
    
    func execute<Target>(_ operation: (Target, _ name: String) -> ()) {
        do {
            let info = try typeInfo(of: Self.self)

            for property in info.properties {
                let child = try property.get(from: self)

                switch child {
                case let t as Target:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                    
                    operation(t, property.name)
                case let dp as DynamicProperty:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")

                    dp.execute(operation)
                case let dyn as Dynamics:
                    // no assertion needed because Dynamics is defined by Apodini
                
                    dyn.execute(operation)
                default:
                    break;
                }
            }
        } catch {
            fatalError("Executing operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on DynamicProperty \((try? typeInfo(of: Self.self))?.name ?? "Unknown Type") failed.")
        }
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> ()) {
        do {
            let info = try typeInfo(of: Self.self)

            for property in info.properties {
                let child = try property.get(from: self)

                switch child {
                case var t as Target:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "\(Target.self) \(property.name) on element \(info.name) must be a struct")
                    
                    mutation(&t, property.name)
                    try property.set(value: t, on: &self)
                case var dp as DynamicProperty:
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")
                    
                    dp.apply(mutation)
                    try property.set(value: dp, on: &self)
                case var dyn as Dynamics:
                    // no assertion needed because Dynamics is defined by Apodini
                
                    dyn.apply(mutation)
                    try property.set(value: dyn, on: &self)
                default:
                    break;
                }
            }
        } catch {
            fatalError("Applying operation on all properties of \((try? typeInfo(of: Target.self))?.name ?? "Unknown Type") on DynamicProperty \((try? typeInfo(of: Self.self))?.name ?? "Unknown Type") failed.")
        }
    }
}


// MARK: Dynamics Implemenation
fileprivate extension Dynamics {
    
    func execute<Target>(_ operation: (Target, _ name: String) -> ()) {
        for (name, element) in self.elements {
            switch element {
            case let t as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Dynamics must be a struct")
                
                operation(t, name)
            case let dp as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Dynamics must be a struct")
                
                dp.execute(operation)
            case let dyn as Dynamics:
                // no assertion needed because Dynamics is defined by Apodini
            
                dyn.execute(operation)
            default:
                break;
            }
        }
    }
    
    mutating func apply<Target>(_ mutation: (inout Target, _ name: String) -> ()) {
        for (name, element) in self.elements {
            switch element {
            case var t as Target:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "\(element.self) \(name) on Dynamics must be a struct")
    
                mutation(&t, name)
                self.elements[name] = t
            case var dp as DynamicProperty:
                assert((Mirror(reflecting: element).displayStyle) == .struct, "DynamicProperty \(name) on Dynamics must be a struct")
                
                dp.apply(mutation)
                self.elements[name] = dp
            case var dyn as Dynamics:
                // no assertion needed because Dynamics is defined by Apodini
            
                dyn.apply(mutation)
                self.elements[name] = dyn
            default:
                break;
            }
        }
    }
}
