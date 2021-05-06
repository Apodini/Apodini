//
//  ContentModule.swift
//  
//
//  Created by Max Obermeier on 09.04.21.
//

import Foundation
import SwiftGraph



// MARK: ContentModule
public protocol ContentModule {
    static var dependencies: [ContentModule.Type] { get }
}

// MARK: DependencyBased Module
public protocol DependencyBased: ContentModule, KnowledgeSource {
    init(from store: ModuleStore) throws
}

extension DependencyBased {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        try self.init(from: BlackboardStore(board: blackboard))
    }
}

// MARK: _HandlerBased Module

// TODO: break up into input/ouput types, so that traversal/reflection is hidden
public protocol _HandlerBased: ContentModule, HandlerBasedKnowledgeSource {
    init<H: Handler>(from handler: H) throws
}

extension _HandlerBased {
    public static var dependencies: [ContentModule.Type] { [] }
}

// MARK: ContextBased Module

public protocol AnyContextBased: ContentModule, KnowledgeSource {
    init(from context: Context) throws
}

extension AnyContextBased {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        try self.init(from: blackboard[AnyEndpointSource.self].context)
    }
}

public protocol OptionalContextBased: AnyContextBased {
    associatedtype Key: OptionalContextKey
    
    init(from value: Key.Value?) throws
}

extension OptionalContextBased {
    public static var dependencies: [ContentModule.Type] { [] }
    
    public init(from context: Context) throws {
        try self.init(from: context.get(valueFor: Key.self))
    }
}

public protocol ContextBased: OptionalContextBased where Key: ContextKey {
    init(from value: Key.Value) throws
}

extension ContextBased {
    public init(from value: Key.Value?) throws {
        try self.init(from: value ?? Key.defaultValue)
    }
}

// MARK: ApplicationBased Module

public protocol ApplicationBased: ContentModule, KnowledgeSource {
    init(from application: Application) throws
}

extension ApplicationBased {
    public static var dependencies: [ContentModule.Type] { [] }
}

extension ApplicationBased {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        try self.init(from: blackboard[Application.self])
    }
}

// MARK: AnyInterfaceExporter Conformance

extension AnyInterfaceExporter {
    var dependencies: [ContentModule.Type] {
        let visitor = ContentModuleExtractor()
        self.accept(visitor)
        return visitor.dependencies
    }
}

private class ContentModuleExtractor: InterfaceExporterVisitor {
    var dependencies: [ContentModule.Type] = []
    
    func visit<I: InterfaceExporter>(exporter: I) {
        self.dependencies = I.dependencies
    }
    
    func visit<I: StaticInterfaceExporter>(staticExporter: I) {
        self.dependencies = I.dependencies
    }
}


// MARK: Module Store

public protocol ModuleStore {
    subscript<M: _HandlerBased>(index: M.Type) -> M { get }
    subscript<M: ApplicationBased>(index: M.Type) -> M { get }
    subscript<M: AnyContextBased>(index: M.Type) -> M { get }
    subscript<M: DependencyBased>(index: M.Type) -> M { get }
}
