//
//  Router.swift
//  
//
//  Created by Max Obermeier on 03.12.20.
//

import Vapor
import NIOWebSocket
import OpenCombine



public enum Message<T> {
    case send(T)
    case error(Error)
}

public protocol Router {
    func register<I: Input, O: Encodable>(_ opener: @escaping (AnyPublisher<I, Never>) -> (default: I, output: AnyPublisher<Message<O>, Error>), on identifier: String)
}

public class VaporWSRouter: Router {
    
    private var registeredAtVapor: Bool = false
    
    private let app: Application
    
    private let path: [PathComponent]
    
    private var endpoints: [String: ContextOpener] = [:]
    
    private var connections: [ConnectionResponsible.ID: ConnectionResponsible] = [:]
    private let connectionsMutex = NSLock()

    public init(_ app: Application, at path: [PathComponent] = ["apodini", "websocket"]) {
        self.app = app
        self.path = path
    }
    
    public func register<I: Input, O: Encodable>(_ opener: @escaping (AnyPublisher<I, Never>) -> (default: I, output: AnyPublisher<Message<O>, Error>), on identifier: String) {
        if self.endpoints[identifier] != nil {
            print("Endpoint \(identifier) on VaporWSRouter registered at \(path.string) was registered more than once.")
        }
        
        self.endpoints[identifier] = { con, ctx in
            TypeSafeContextResponsible(opener, con: con, context: ctx)
        }
        
        if !registeredAtVapor {
            self.registeredAtVapor = true
            self.registerRouteToVapor()
        }
    }
    
    
    private func registerRouteToVapor() {
        app.routes.grouped(self.path).webSocket(onUpgrade: { _, ws in
            self.connectionsMutex.lock()
            let cr = ConnectionResponsible(ws, onClose: { id in
                self.connectionsMutex.lock()
                self.connections[id] = nil
                self.connectionsMutex.unlock()
            }, endpoints: self.endpoints)
            self.connections[cr.id] = cr
            self.connectionsMutex.unlock()
        })
    }
        
}
