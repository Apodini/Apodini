//
//  ContextResponsible.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

@_implementationOnly import Vapor
import _Concurrency
import NIOWebSocket
import ApodiniExtension
import ApodiniUtils


protocol ContextResponsible {
    func receive(_ parameters: [String: Any], _ data: Data) throws
    
    func complete()
}



class TypeSafeContextResponsible<I: Input, O: Encodable>: ContextResponsible {
    class Subscribable: ApodiniExtension.Subscribable {
        typealias Event = InputEvent
        
        typealias Handle = Void
        
        var onInput: ((InputEvent) -> Void)?
        
        func register(_ callback: @escaping (InputEvent) -> Void) {
            self.onInput = callback
        }
    }
    
    enum InputEvent: CompletionCandidate {
        case input(I)
        case completion
        
        var isCompletion: Bool {
            switch self {
            case .completion:
                return true
            default:
                return false
            }
        }
    }
    
    var input: I
    
    let send: (O) -> Void
    let sendError: (Error) -> Void
    let destruct: () -> Void
    let close: (WebSocketErrorCode) -> Void
    
    let inputReceiver: Subscribable
    
    convenience init(
        _ opener: @escaping (AnyAsyncSequence<I>, EventLoop, Vapor.Request) ->
            (default: I, output: AnyAsyncSequence<Message<O>>),
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
        _ opener: @escaping (AnyAsyncSequence<I>, EventLoop, Vapor.Request) -> (default: I, output: AnyAsyncSequence<Message<O>>),
        eventLoop: EventLoop,
        send: @escaping (O) -> Void,
        sendError: @escaping (Error) -> Void,
        destruct: @escaping () -> Void,
        close: @escaping (WebSocketErrorCode) -> Void,
        request: Vapor.Request
    ) {
        let subscribable = Subscribable()
        
        self.inputReceiver = subscribable
        
        var sequence = AsyncSubscribingSequence(subscribable)
        sequence.connect()
        
        let (defaultInput, output) = opener(try! sequence
                                                .prefix(while: { (event: InputEvent) in
                                                    if case .input(_) = event {
                                                        return true
                                                    }
                                                    return false
                                                })
                                                .map { event in
                                                    guard case let .input(input) = event else {
                                                        fatalError("Prefix should have cut this off!")
                                                    }
                                                    return input
                                                }
                                                .typeErased, eventLoop, request)
        
        self.input = defaultInput
        
        _Concurrency.Task {
            do {
                for try await message in output {
                    switch message {
                    case .message(let output):
                        send(output)
                    case .error(let error):
                        sendError(error)
                    }
                }
                destruct()
            } catch {
                sendError(error)
                close((error as? WSClosingError)?.code ?? .unexpectedServerError)
            }
        }
        
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
            self.inputReceiver.onInput?(.input(self.input))
        }
    }
    
    func complete() {
        self.inputReceiver.onInput?(.completion)
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
