//
//  WebSocketErrorOptions.swift
//  
//
//  Created by Max Obermeier on 20.01.21.
//

import NIOWebSocket


// MARK: WebSocketErrorCode

extension WebSocketErrorCode: StandardErrorCompliantOption {
    static func `default`(for type: ErrorType) -> Self {
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
    public static func webSocketErrorCode(_ code: WebSocketErrorCode) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .webSocketErrorCode, value: code)
    }
}

// MARK: WSConnectionConsequence

/// An enum that specifies the effect an `Error` has on the associated
/// WebSocket connection and context.
public enum WSConnectionConsequence: StandardErrorCompliantOption {
    /// The associated error is reported to the client, but the
    /// context remains open.
    case none
    /// The associated error is reported to the client and the
    /// associated context is closed.
    case closeContext
    /// The associated error is reported to the client and the
    /// associated channel is closed with the given code.
    case closeChannel
    
    static func `default`(for type: ErrorType) -> Self {
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

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == WSConnectionConsequence {
    static let wsConnectionConsequence = PropertyOptionKey<ErrorOptionNameSpace, WSConnectionConsequence>()
}

extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    public static func wsConnectionConsequence(_ consequence: WSConnectionConsequence) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .wsConnectionConsequence, value: consequence)
    }
}

// MARK: WSErrorType
typealias WSErrorType = ErrorType

extension WSErrorType: StandardErrorCompliantOption {
    static func `default`(for type: ErrorType) -> Self {
        return type
    }
}

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == WSErrorType {
    static let wsErrorType = PropertyOptionKey<ErrorOptionNameSpace, WSErrorType>()
}

extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    static func wsErrorType(_ type: WSErrorType) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .wsErrorType, value: type)
    }
}
