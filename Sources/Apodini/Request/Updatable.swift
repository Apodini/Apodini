//
//  Updatable.swift
//
//
//  Created by Max Obermeier on 09.12.20.
//

import Foundation
import Runtime
import Vapor

protocol Updatable {
    var id: UUID { get }
    mutating func update(with: Any?)
}

protocol Updater {
    func update(_: inout Updatable)
}

extension Parameter: Updatable {

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

func update<E>(_ element: inout E, with updater: Updater) {
    apply({ (up: inout Updatable) in
        updater.update(&up)
    }, to: &element)
}

func updateAndExecute<E, R>(_ element: E, with updater: Updater, executing method: (E) -> EventLoopFuture<R>) -> EventLoopFuture<R> {
    var element = element
    update(&element, with: updater)
    
    return method(element)
}

class RequestDecoderBasedUpdater: Updater {
    let decoder: RequestInjectableDecoder
    let request: _Request
    let parameters: [UUID: EndpointParameter]
    
    init(decoder: RequestInjectableDecoder, request: _Request, parameters: [EndpointParameter]) {
        self.decoder = decoder
        self.request = request
        
        var parameterMap: [UUID: EndpointParameter] = [:]
        for parameter in parameters {
            parameterMap[parameter.id] = parameter
        }
        self.parameters = parameterMap
    }
    
    func update(_ updatable: inout Updatable) {
        if let parameter = parameters[updatable.id] {
            let value = decoder.decode(parameter, from: self.request.wrappedValue)
            
            updatable.update(with: value)
        }
    }
}
