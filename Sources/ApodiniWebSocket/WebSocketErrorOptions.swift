//
//  WebSocketErrorOptions.swift
//  
//
//  Created by Max Obermeier on 20.01.21.
//

import Apodini
import NIOWebSocket

// MARK: WebSocketErrorCode

extension WebSocketErrorCode: ApodiniErrorCompliantOption {
    public static func `default`(for type: ErrorType) -> Self {
        switch type {
        case .badInput:
            return .dataInconsistentWithMessage
        case .serverError:
            return .unexpectedServerError
        default:
            return .normalClosure
        }
    }
}

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == WebSocketErrorCode {
    static let webSocketErrorCode = PropertyOptionKey<ErrorOptionNameSpace, WebSocketErrorCode>()
}

extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    /// An option that holds websocket error codes.
    public static func webSocketErrorCode(_ code: WebSocketErrorCode) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .webSocketErrorCode, value: code)
    }
}

// MARK: WebSocketConnectionConsequence

/// An enum that specifies the effect an `Error` has on the associated
/// WebSocket connection and context.
public enum WebSocketConnectionConsequence: ApodiniErrorCompliantOption {
    /// The associated error is reported to the client, but the
    /// context remains open.
    case none
    /// The associated error is reported to the client and the
    /// associated context is closed.
    case closeContext
    /// The associated error is reported to the client and the
    /// associated channel is closed with the given code.
    case closeChannel
    
    public static func `default`(for type: ErrorType) -> Self {
        switch type {
        case .badInput:
            return .none
        case .notFound:
            return .none
        case .unauthenticated:
            return .closeContext
        case .forbidden:
            return .closeChannel
        case .serverError:
            return .closeContext
        case .notAvailable:
            return .closeContext
        case .other:
            return .closeContext
        }
    }
}

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == WebSocketConnectionConsequence {
    static let webSocketConnectionConsequence = PropertyOptionKey<ErrorOptionNameSpace, WebSocketConnectionConsequence>()
}

extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    /// An option that sepcifies the consequence an associated error has on the WebSocket connection and/or context.
    public static func webSocketConnectionConsequence(_ consequence: WebSocketConnectionConsequence) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .webSocketConnectionConsequence, value: consequence)
    }
}
