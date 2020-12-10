//
//  Updatable.swift
//
//
//  Created by Max Obermeier on 09.12.20.
//

import Foundation
import Runtime

protocol UpdatableProperty {
    var id: UUID { get }
    mutating func update(with: Any?)
}

protocol Updater {
    func update(_: inout UpdatableProperty)
}

protocol IdentifiableUpdater: Updater {
    var id: UUID { get }
}

protocol Updatable {
    mutating func update(with: [UUID: Updater])
}


extension Parameter: UpdatableProperty {

    mutating func update(with element: Any?) {
        if let e = element as? Element {
            self.element = e // TODO: remove this case
        } else if let e = element as? Element? {
            self.element = e
        } else {
            fatalError("Mismatching type when updating \(self) with \(element ?? "nil")")
        }
    }
}

func update<E>(_ element: inout E, with updaters: [UUID: Updater]) {
    do {
        let info = try typeInfo(of: E.self)

        for property in info.properties {
            let child = try property.get(from: element)

            switch child {
            case var up as UpdatableProperty:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Updatable \(property.name) on element \(info.name) must be a struct")
                if let updater = updaters[up.id] {
                    updater.update(&up)
                    try property.set(value: up, on: &element)
                }
            case var dp as DynamicProperty:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "DynamicProperty \(property.name) on element \(info.name) must be a struct")

                update(&dp, with: updaters)
                try property.set(value: dp, on: &element)
            case var u as Updatable:
                assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Updatable \(property.name) on element \(info.name) must be a struct")

                u.update(with: updaters)
                try property.set(value: u, on: &element)
            default:
                break;
            }
        }
    } catch {
        fatalError("Updating element \(element) failed.")
    }
}


func update<E>(_ element: inout E,from updaters: [IdentifiableUpdater]) {
    var um: [UUID: Updater] = [:]
    
    for u in updaters {
        um[u.id] = u
    }
    
    update(&element, with: um)
}
