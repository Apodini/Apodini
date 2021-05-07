//
//  Blackboard.swift
//  
//
//  Created by Max Obermeier on 03.05.21.
//

import Foundation

/// A storage for `KnowledgeSource`s. The `Blackboard` takes care of initialization and storage of `KnowledgeSource`s.
/// It also allows for mutating `KnowledgeSource`s. Most initializations are performed lazily.
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
    func request<S, B>(_ type: S.Type, using blackboard: B) throws -> S where S: KnowledgeSource, B: Blackboard
}

extension IndependentBlackboard {
    func request<S>(_ type: S.Type) throws -> S where S : KnowledgeSource {
        try self.request(type, using: self)
    }
}

final class LocalBlackboard<L: IndependentBlackboard, G: Blackboard>: Blackboard {
    private let global: G
    private var local: L
    
    init<H: Handler>(_ global: G, hiddenFor restrictions: [TruthAnchor.Type] = [], using handler: H, _ context: Context) {
        self.global = global
        self.local = L()
        
        self.local[EndpointSource<H>.self] = EndpointSource(handler: handler, context: context)
        self.local[AnyEndpointSource.self] = AnyEndpointSource(handler: handler, context: context)
        
        if var blackboards = try? global.request(Blackboards.self) {
            blackboards.addBoard(self, hiddenFor: restrictions)
            global[Blackboards.self] = blackboards
        }
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
            switch type.preference {
            case .local:
                local[type] = newValue
            case .global:
                global[type] = newValue
            }
        }
    }
    
    func request<S>(_ type: S.Type) throws -> S where S : KnowledgeSource {
        switch type.preference {
        case .local:
            do {
                return try local.request(type, using: self)
            } catch KnowledgeError.unsatisfiableDependency(_, _) {
                return try global.request(type)
            }
        case .global:
            do {
                return try global.request(type)
            } catch KnowledgeError.unsatisfiableDependency(_, _) {
                return try local.request(type, using: self)
            }
        }
    }
}


struct GlobalBlackboard<B: IndependentBlackboard>: Blackboard, StorageKey {
    typealias Value = B
    
    private unowned let app: Application
    
    init(_ app: Application) {
        self.app = app
        
        if app.storage[Self.self] == nil {
            let board = getOrInitializeBlackboard()
            board[Application.self] = app
            board[Blackboards.self] = Blackboards()
        }
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

final class LazyHashmapBlackboard: IndependentBlackboard {
    private var storage: [ObjectIdentifier: KnowledgeSource] = [:]
    
    subscript<S>(type: S.Type) -> S where S : KnowledgeSource {
        get {
            do {
                return try request(type, using: self)
            } catch {
                fatalError("Failed creating KnowledgeSource \(type): \(error)")
            }
        }
        set {
            let id = ObjectIdentifier(type)
            storage[id] = newValue
        }
    }
    
    func request<S, B>(_ type: S.Type, using blackboard: B) throws -> S where S : KnowledgeSource, B: Blackboard {
        let id = ObjectIdentifier(type)
        if let stored = storage[id] as? S {
            return stored
        }
        
        let new = try S(blackboard)
        storage[id] = new
        return new
    }
}

public class MockBlackboard: Blackboard {
    
    private var content: [ObjectIdentifier: KnowledgeSource]
    
    public init(_ contents: (KnowledgeSource.Type, KnowledgeSource)...) {
        var c = [ObjectIdentifier: KnowledgeSource]()
        for content in contents {
            c[ObjectIdentifier(content.0)] = content.1
        }
        self.content = c
    }
    
    public subscript<S>(_ type: S.Type) -> S where S : KnowledgeSource {
        get {
            content[ObjectIdentifier(type)]! as! S
        }
        set {
            content[ObjectIdentifier(type)] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S : KnowledgeSource {
        self[type]
    }
}

// TODO: remove
struct BlackboardStore: ModuleStore {
    let board: Blackboard
    
    subscript<M>(index: M.Type) -> M where M : DependencyBased {
        board[index]
    }
    
    subscript<M>(index: M.Type) -> M where M : AnyContextBased {
        board[index]
    }
    
    subscript<M>(index: M.Type) -> M where M : ApplicationBased {
        board[index]
    }
    
    subscript<M>(index: M.Type) -> M where M : _HandlerBased {
        board[index]
    }
}
