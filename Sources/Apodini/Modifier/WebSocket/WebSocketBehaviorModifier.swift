//
//  File.swift
//  
//
//  Created by Max Obermeier on 15.11.20.
//


import NIOWebSocket

/// Defines the bahavior of a WebSocket after a `Component`'s `handle` was called successfully.
public enum WebSocketSuccessBehavior {
    /// Default behavior. The WebSocket remains open  if `handle` doesn't throw.
    case `default`
    /// The WebSocket is closed if `handle` returns without error after the `handle`'s response
    /// has been sent.
    case close(WebSocketErrorCode = .normalClosure)
}

struct WebSocketSuccessBehaviorContextKey: ContextKey {
    static var defaultValue: WebSocketSuccessBehavior = .default
    
    static func reduce(value: inout WebSocketSuccessBehavior, nextValue: () -> WebSocketSuccessBehavior) {
        value = nextValue()
    }
}

public struct WebSocketSuccessBehaviorModifier<ModifiedComponent: Component>: Modifier {
    let component: ModifiedComponent
    let behavior: WebSocketSuccessBehavior
    
    
    init(_ component: ModifiedComponent, behavior: WebSocketSuccessBehavior) {
        self.component = component
        self.behavior = behavior
    }
}


extension WebSocketSuccessBehaviorModifier: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(WebSocketSuccessBehaviorContextKey.self, value: behavior, scope: .environment)
        component.visit(visitor)
    }
}


extension Component {
    public func webSocketOnSuccess(_ behavior: WebSocketSuccessBehavior) -> WebSocketSuccessBehaviorModifier<Self> {
        WebSocketSuccessBehaviorModifier(self, behavior: behavior)
    }
}

/// Defines the bahavior of a WebSocket after a `Component`'s `handle` was called and threw an
/// error.
public enum WebSocketErrorBehavior {
    /// Default behavior. The WebSocket remains open except for fatal errors. An error message is
    /// sent in either case. This message is derived from the error thrown.
    case `default`
    /// The WebSocket is closed if `handle` throws an error after the `handle`'s response
    /// has been sent.  The code is used only if the error thrown does not provide its own.
    case close(WebSocketErrorCode = .unexpectedServerError)
}

struct WebSocketErrorBehaviorContextKey: ContextKey {
    static var defaultValue: WebSocketErrorBehavior = .default

    static func reduce(value: inout WebSocketErrorBehavior, nextValue: () -> WebSocketErrorBehavior) {
        value = nextValue()
    }
}

public struct WebSocketErrorBehaviorModifier<ModifiedComponent: Component>: Modifier {
    let component: ModifiedComponent
    let behavior: WebSocketErrorBehavior


    init(_ component: ModifiedComponent, behavior: WebSocketErrorBehavior) {
        self.component = component
        self.behavior = behavior
    }
}


extension WebSocketErrorBehaviorModifier: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(WebSocketErrorBehaviorContextKey.self, value: behavior, scope: .environment)
        component.visit(visitor)
    }
}


extension Component {
    public func webSocketOnError(_ behavior: WebSocketErrorBehavior) -> WebSocketErrorBehaviorModifier<Self> {
        WebSocketErrorBehaviorModifier(self, behavior: behavior)
    }
}
