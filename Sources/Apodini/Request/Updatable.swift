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
            self.element = e
        } else if let e = element as? Element? {
            self.element = e
        } else {
            fatalError("Mismatching type when updating \(self) with \(element ?? "nil")")
        }
    }
}

func update<E>(_ element: inout E, with updaters: [UUID: Updater]) {
    apply({ (up: inout UpdatableProperty) in
        if let updater = updaters[up.id] {
            updater.update(&up)
        }
    }, to: &element)
}


func update<E>(_ element: inout E,from updaters: [IdentifiableUpdater]) {
    var um: [UUID: Updater] = [:]
    
    for u in updaters {
        um[u.id] = u
    }
    
    update(&element, with: um)
}
