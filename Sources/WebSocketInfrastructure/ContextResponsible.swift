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
    func receive(_ parameters: [String:Any], _ data: Data) throws
    
    func complete()
}

class TypeSafeContextResponsible<I: Input, O: Encodable>: ContextResponsible {
    var input: I
    let receiver: PassthroughSubject<I, Never>
    
    let outputSubscriber: AnyCancellable
    
    let send: (Encodable) -> ()
    let destruct: () -> ()
    let close: (WebSocketErrorCode) -> ()
    
    convenience init(_ opener: @escaping (AnyPublisher<I, Never>, EventLoop, Database?) -> (default: I, output: AnyPublisher<Message<O>, Error>), con: ConnectionResponsible, context: UUID) {
        
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
        _ opener: @escaping (AnyPublisher<I, Never>,  EventLoop, Database?) -> (default: I, output: AnyPublisher<Message<O>, Error>),
        eventLoop: EventLoop,
        database: Database?,
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
                send("\(err)")
            }
        })
        
        self.send = send
        self.destruct = destruct
        self.close = close
    }
    
    func receive(_ parameters: [String:Any], _ data: Data) throws {
        for (parameter, _) in parameters {
            switch self.input.update(parameter, using: ClientMessageParameterDecoder(data: data, name: parameter)) {
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


// MARK: Decoding Helpers

private struct ClientMessageParameterDecoder: ParameterDecoder {
    let data: Data
    let name: String
    
    func decode<T>(_ type: T.Type) throws -> T?? where T : Decodable {
        try JSONDecoder().decodeParameter(type, from: self.data, named: name)
    }
}

private extension JSONDecoder {

    func decodeParameter<T: Decodable>(_ type: T.Type, from data: Data, named key: String) throws -> T?? {
        // Pass the top level key to the decoder.
        userInfo[.parameterName] = key

        let root = try decode(ParametersWrapper<ParameterWrapper<T>>.self, from: data)
        return root.parameters.value
    }

}

private struct ParameterWrapper<T: Decodable>: Decodable {
    
    struct AnyKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
          self.stringValue = stringValue
        }
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
    

    var value: T??

    init(from decoder: Decoder) throws {
        guard let parameterName = decoder.userInfo[.parameterName] as? String else {
            fatalError("Tried to decode parameter without parameterName.")
        }

        let key = AnyKey(stringValue: parameterName)!

        let container = try decoder.container(keyedBy: AnyKey.self)

        if !container.contains(key) {
            self.value = nil
        } else if try container.decodeNil(forKey: key) {
            self.value = .some(nil)
        } else {
            self.value = try container.decode(T.self, forKey: key)
        }
    }
}

private extension CodingUserInfoKey {

    static let parameterName = CodingUserInfoKey(rawValue: "parameterName")!

}

private struct ParametersWrapper<T>: Decodable where T: Decodable {
    let parameters: T
}
