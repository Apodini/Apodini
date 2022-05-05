//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A storage for `KnowledgeSource`s. The `SharedRepository` takes care of initialization and storage of `KnowledgeSource`s.
/// It also allows for mutating `KnowledgeSource`s. Most initializations are performed lazily.
public protocol SharedRepository {
    /// `SharedRepository`s can be read from and written to based on a `KnowledgeSource`'s type. If not present yet,
    /// the `SharedRepository` takes care of initializing the `KnowledgeSource`.
    subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource { get nonmutating set }
    
    /// An alternative for the `SharedRepository`'s subscript for graceful error handling.
    func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource
}

extension SharedRepository {
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


protocol IndependentSharedRepository: SharedRepository {
    init()
    func request<S, B>(_ type: S.Type, using sharedRepository: B) throws -> S where S: KnowledgeSource, B: SharedRepository
}

extension IndependentSharedRepository {
    func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try self.request(type, using: self)
    }
}

final class LocalSharedRepository<L: IndependentSharedRepository, G: SharedRepository>: SharedRepository {
    private let global: G
    private var local: L
    
    init<H: Handler>(_ global: G, hiddenFor restrictions: [TruthAnchor.Type] = [], using handler: H, _ context: Context) {
        self.global = global
        self.local = L()
        
        let source = EndpointSource(handler: handler, context: context)
        self.local[EndpointSource<H>.self] = source
        self.local[AnyEndpointSource.self] = AnyEndpointSource(source: source)
        
        if var sharedRepositorys = try? global.request(SharedRepositorys.self) {
            sharedRepositorys.addSharedRepository(self, hiddenFor: restrictions)
            global[SharedRepositorys.self] = sharedRepositorys
        }
    }
    
    subscript<S>(type: S.Type) -> S where S: KnowledgeSource {
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
    
    func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
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


struct GlobalSharedRepository<B: IndependentSharedRepository>: SharedRepository, StorageKey {
    typealias Value = B
    
    private unowned let app: Application
    
    init(_ app: Application) {
        self.app = app
        
        if app.storage[Self.self] == nil {
            let sharedRepository = getOrInitializeSharedRepository()
            sharedRepository[Application.self] = app
            sharedRepository[SharedRepositorys.self] = SharedRepositorys()
        }
    }
    
    subscript<S>(type: S.Type) -> S where S: KnowledgeSource {
        get {
            getOrInitializeSharedRepository()[type]
        }
        nonmutating set {
            getOrInitializeSharedRepository()[type] = newValue
        }
    }
    
    func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try getOrInitializeSharedRepository().request(type)
    }
    
    private func getOrInitializeSharedRepository() -> Value {
        if let sharedRepository = app.storage[Self.self] {
            return sharedRepository
        }
        
        let sharedRepository = B()
        app.storage.set(Self.self, to: sharedRepository)
        return sharedRepository
    }
}

final class LazyHashmapSharedRepository: IndependentSharedRepository {
    private var storage: [ObjectIdentifier: KnowledgeSource] = [:]
    
    subscript<S>(type: S.Type) -> S where S: KnowledgeSource {
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
    
    func request<S, B>(_ type: S.Type, using sharedRepository: B) throws -> S where S: KnowledgeSource, B: SharedRepository {
        let id = ObjectIdentifier(type)
        if let stored = storage[id] as? S {
            return stored
        }
        
        do {
            let new = try S(sharedRepository)
            storage[id] = new
            return new
        } catch KnowledgeError.instancePresent {
            if let instance = storage[id] as? S {
                return instance
            }
            throw KnowledgeError.initializationFailed
        }
    }
}
