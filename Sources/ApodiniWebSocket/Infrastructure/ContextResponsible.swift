//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@_implementationOnly import Vapor
@_implementationOnly import OpenCombine
import NIOWebSocket


protocol ContextResponsible {
    func receive(_ parameters: [String: Any], _ data: Data) throws
    
    func complete()
}

class TypeSafeContextResponsible<I: Input, O: Encodable>: ContextResponsible {
    var input: I
    let receiver: PassthroughSubject<I, Never>
    
    let outputSubscriber: AnyCancellable
    
    let send: (O) -> Void
    let sendError: (Error) -> Void
    let destruct: () -> Void
    let close: (WebSocketErrorCode) -> Void
    
    convenience init(
        _ opener: @escaping (AnyPublisher<I, Never>, EventLoop, Vapor.Request) ->
            (default: I, output: AnyPublisher<Message<O>, Error>),
        con: ConnectionResponsible,
        context: UUID) {
        self.init(
            opener,
            eventLoop: con.websocket.eventLoop,
            send: { message in
                con.send(message, in: context)
            },
            sendError: { error in con.send(error, in: context) },
            destruct: {
                con.destruct(context)
            },
            close: con.close,
            request: con.request)
    }
    
    init(
        _ opener: @escaping (AnyPublisher<I, Never>, EventLoop, Vapor.Request) -> (default: I, output: AnyPublisher<Message<O>, Error>),
        eventLoop: EventLoop,
        send: @escaping (O) -> Void,
        sendError: @escaping (Error) -> Void,
        destruct: @escaping () -> Void,
        close: @escaping (WebSocketErrorCode) -> Void,
        request: Vapor.Request
    ) {
        let receiver = PassthroughSubject<I, Never>()
        
        let (defaultInput, output) = opener(receiver.eraseToAnyPublisher(), eventLoop, request)
        
        self.input = defaultInput
        
        self.receiver = receiver
        
        self.outputSubscriber = output.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                sendError(error)
                close((error as? WSClosingError)?.code ?? .unexpectedServerError)
            case .finished:
                destruct()
            }
        }, receiveValue: { message in
            switch message {
            case .message(let output):
                send(output)
            case .error(let error):
                sendError(error)
            }
        })
        
        self.send = send
        self.sendError = sendError
        self.destruct = destruct
        self.close = close
    }
    
    func receive(_ parameters: [String: Any], _ data: Data) throws {
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
        case let .invalid(name, error):
            return "Invalid input: \(name) \(error.reason)"
        }
    }
}


// MARK: Decoding Helpers

private struct ClientMessageParameterDecoder: ParameterDecoder {
    let data: Data
    let name: String
    
    func decode<T>(_ type: T.Type) throws -> T?? where T: Decodable {
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
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }
    
    var value: T??

    init(from decoder: Decoder) throws {
        guard let parameterName = decoder.userInfo[.parameterName] as? String else {
            fatalError("Tried to decode parameter without parameterName.")
        }

        // swiftlint:disable:next force_unwrapping
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
    // swiftlint:disable:next force_unwrapping
    static let parameterName = CodingUserInfoKey(rawValue: "parameterName")!
}

private struct ParametersWrapper<T>: Decodable where T: Decodable {
    let parameters: T
}
