//
//  ContextResponsible.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

import Fluent
import Vapor
import OpenCombine
import NIOWebSocket


protocol ContextResponsible {
    func receive(_ parameters: [String:Any]) throws
    
    func complete()
}

class TypeSafeContextResponsible<I: Input, O: Encodable>: ContextResponsible {
    var input: I
    let receiver: PassthroughSubject<I, Never>
    
    let outputSubscriber: AnyCancellable
    
    let send: (Encodable) -> ()
    let destruct: () -> ()
    let close: (WebSocketErrorCode) -> ()
    
    convenience init(_ opener: @escaping (AnyPublisher<I, Never>, EventLoop, Database) -> (default: I, output: AnyPublisher<Message<O>, Error>), con: ConnectionResponsible, context: UUID) {
        
        self.init(opener, eventLoop: con.ws.eventLoop, database: con.db, send: { msg in
            if let o = msg as? O {
                con.send(o, in: context)
            } else if let s = msg as? String {
                con.send(s, in: context)
            } else {
                print("Could not send message: \(msg)")
            }
        }, destruct: {
            con.destruct(context)
        }, close: con.close)
    }
    
    init(
        _ opener: @escaping (AnyPublisher<I, Never>,  EventLoop, Database) -> (default: I, output: AnyPublisher<Message<O>, Error>),
        eventLoop: EventLoop,
        database: Database,
        send: @escaping (Encodable) -> (),
        destruct: @escaping () -> (),
        close: @escaping (WebSocketErrorCode) -> ()
    ) {
        let receiver = PassthroughSubject<I, Never>()
        
        let (defaultInput, output) = opener(receiver.eraseToAnyPublisher(), eventLoop, database)
        
        self.input = defaultInput
        
        self.receiver = receiver
        
        self.outputSubscriber = output.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(_):
                // TODO: allow for custom error-codes + messages
                close(.unexpectedServerError)
            case .finished:
                destruct()
            }
        }, receiveValue: { message in
            switch message {
            case .send(let output):
                send(output)
            case .error(let err):
                send(err.localizedDescription)
            }
        })
        
        self.send = send
        self.destruct = destruct
        self.close = close
    }
    
    func receive(_ parameters: [String:Any]) throws {
        for (parameter, value) in parameters {
            switch self.input.update(parameter, with: value) {
            case .error(let error):
                throw InputError.invalid(parameter, error)
            case .ok:
                break
            }
        }
        
        switch self.input.check() {
        case .missing(let parameters):
            throw InputError.missing(parameters)
        case .ok:
            self.input.apply()
            self.receiver.send(self.input)
        }
        
    }
    
    func complete() {
        self.receiver.send(completion: .finished)
    }
    
}

enum InputError: WSError {
    case missing([String])
    case invalid(String, ParameterUpdateError)
    
    var reason: String {
        switch self {
        case .missing(let parameters):
            return "Invalid input: missing parameters \(parameters.joined(separator: ", "))"
        case .invalid(let name, let error):
            return "Invalid input: \(name) \(error.reason)"
        }
    }
}
