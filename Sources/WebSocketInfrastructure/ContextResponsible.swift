//
//  ContextResponsible.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

import Vapor
import OpenCombine
import NIOWebSocket


protocol ContextResponsible {
    
    func receive(_ parameters: [String:Any])
    
    func complete()
    
}

class TypeSafeContextResponsible<I: Input, O: Encodable>: ContextResponsible {
    
    var input: I
    let receiver: PassthroughSubject<I, Never>
    
    let outputSubscriber: AnyCancellable
    
    let send: (Encodable) -> ()
    let destruct: () -> ()
    let close: (WebSocketErrorCode) -> ()
    
    convenience init(_ opener: @escaping (AnyPublisher<I, Never>) -> (default: I, output: AnyPublisher<Message<O>, Error>), con: ConnectionResponsible, context: UUID) {
        
        self.init(opener, send: { msg in
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
    
    init(_ opener: @escaping (AnyPublisher<I, Never>) -> (default: I, output: AnyPublisher<Message<O>, Error>), send: @escaping (Encodable) -> (), destruct: @escaping () -> (), close: @escaping (WebSocketErrorCode) -> ()) {
        let receiver = PassthroughSubject<I, Never>()
        
        let (defaultInput, output) = opener(receiver.eraseToAnyPublisher())
        
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
    
    func receive(_ parameters: [String:Any]) {
        var abort = false
        for (parameter, value) in parameters {
            switch self.input.update(parameter, with: value) {
            case .error(.badType):
                abort = true
                self.send("Invalid message: Bad type for parameter \(parameter)")
            case .error(.notMutable):
                abort = true
                self.send("Invalid message: Cannot update parameter \(parameter): \(parameter) is a constant parameter")
            case .error(.notExistant):
                abort = true
                self.send("Invalid message: Input has no parameter \(parameter)")
            case .ok:
                break
            }
        }
        if abort {
            return
        }
        switch self.input.check() {
        case .missing(let parameters):
            self.send("Invalid message: Missing parameters \(parameters.joined(separator: ", "))")
            return
        case .ok:
            self.input.apply()
            self.receiver.send(self.input)
        }
        
    }
    
    func complete() {
        self.receiver.send(completion: .finished)
    }
    
}
