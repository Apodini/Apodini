//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


public struct EmptyComponent: Component, Visitable {
    public var content: some Component {
        return { () -> Self in
            fatalError()
        }()
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {}
}


public enum DummyNever {}


// MARK: Component

extension Never: Component {
    public typealias Content = Never
    public var content: Self.Content {
        fatalError()
    }
}

extension Component where Content == Never {
    public var content: Self.Content {
        fatalError()
    }
}


extension DummyNever: Component {
    public typealias Content = Never
    public var content: Self.Content {
        fatalError()
    }
}

extension Component where Content == DummyNever {
    public var content: Self.Content {
        fatalError()
    }
}


// MARK: Handler

extension Never: Encodable {
    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}

extension Handler where Response == Never {
    public func handle() -> Self.Response {
        fatalError()
    }
}


extension DummyNever: Encodable {
    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}

extension Handler where Response == DummyNever {
    public func handle() -> Self.Response {
        fatalError()
    }
}
