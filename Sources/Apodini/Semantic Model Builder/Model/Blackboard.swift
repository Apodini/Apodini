//
//  Blackboard.swift
//  
//
//  Created by Max Obermeier on 03.05.21.
//

import Foundation

public protocol Blackboard {
    subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource { get nonmutating set }
    
    /// An alternative for the `Blackboard`'s subscript for graceful error handling.
    func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource
}

extension Blackboard {
    subscript<S>() -> S where S: KnowledgeSource {
        get {
            self[S.self]
        }
        set {
            self[S.self] = newValue
        }
    }
    
    func request<S>() throws -> S where S: KnowledgeSource {
        try self.request(S.self)
    }
}


protocol IndependentBlackboard: Blackboard {
    init()
}

protocol LazyBlackboard: Blackboard {
    func peak<S>(_ type: S.Type) -> S? where S: KnowledgeSource
}

final class LocalBlackboard<L: IndependentBlackboard, G: Blackboard>: Blackboard {
    private let global: G
    private var local: L
    
    init<H: Handler>(_ global: G, hiddenFor restrictions: [TruthAnchor.Type] = [], using handler: H, _ context: Context) {
        self.global = global
        self.local = L()
        
        global[Blackboards.self].addBoard(self, hiddenFor: restrictions)
    }
    
    subscript<S>(type: S.Type) -> S where S : KnowledgeSource {
        get {
            do {
                return try request(type)
            } catch {
                fatalError("Failed creating KnowledgeSource \(type): \(error)")
            }
        }
        set {
            local[type] = newValue
        }
    }
    
    func request<S>(_ type: S.Type) throws -> S where S : KnowledgeSource {
        if let stored = (local as? LazyBlackboard)?.peak(type) ?? (global as? LazyBlackboard)?.peak(type) {
            return stored
        }
        
        do {
            return try local.request(type)
        } catch KnowledgeError.unsatisfiableDependency(_, _) {
            return try global.request(type)
        }
    }
}


struct GlobalBlackboard<B: IndependentBlackboard>: Blackboard, StorageKey {
    typealias Value = B
    
    private unowned let app: Application
    
    init(_ app: Application) {
        self.app = app
        
        getOrInitializeBlackboard()[Application.self] = app
    }
    
    subscript<S>(type: S.Type) -> S where S : KnowledgeSource {
        get {
            getOrInitializeBlackboard()[type]
        }
        nonmutating set {
            getOrInitializeBlackboard()[type] = newValue
        }
    }
    
    func request<S>(_ type: S.Type) throws -> S where S : KnowledgeSource {
        return try getOrInitializeBlackboard().request(type)
    }
    
    private func getOrInitializeBlackboard() -> Value {
        if let bb = app.storage[Self.self] {
            return bb
        }
        
        let bb = B()
        app.storage.set(Self.self, to: bb)
        return bb
    }
}

extension GlobalBlackboard: LazyBlackboard where B: LazyBlackboard {
    func peak<S>(_ type: S.Type) -> S? where S : KnowledgeSource {
        getOrInitializeBlackboard().peak(type)
    }
}

final class LazyHashmapBlackboard: LazyBlackboard, IndependentBlackboard {
    private var storage: [ObjectIdentifier: KnowledgeSource] = [:]
    
    subscript<S>(type: S.Type) -> S where S : KnowledgeSource {
        get {
            do {
                return try request(type)
            } catch {
                fatalError("Failed creating KnowledgeSource \(type): \(error)")
            }
        }
        set {
            let id = ObjectIdentifier(type)
            storage[id] = newValue
        }
    }
    
    func request<S>(_ type: S.Type) throws -> S where S : KnowledgeSource {
        let id = ObjectIdentifier(type)
        if let stored = storage[id] as? S {
            return stored
        }
        
        let new = try S(self)
        storage[id] = new
        return new
    }
    
    func peak<S>(_ type: S.Type) -> S? where S : KnowledgeSource {
        storage[ObjectIdentifier(type)] as? S
    }
}
