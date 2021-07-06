//
//  RequestDecoding.swift
//  
//
//  Created by Max Obermeier on 24.06.21.
//

import Foundation
import Apodini
import ApodiniUtils
import OpenCombine

// MARK: RequestBasis

/// This protocol captures the basics of Apodini's `Request` protocol.
///
/// A type of this protocol can be used together with a ``DecodingStrategy`` and an `EventLoop`
/// to construct a `Request` using ``DecodingStrategy/decodeRequest(from:with:with:)``.
///
/// ``DefaultRequestBasis`` can be used to construct an instance of this type from its components.
public protocol RequestBasis {
    /// Returns a description of the Request.
    var description: String { get }
    /// Returns a debug description of the Request.
    var debugDescription: String { get }
    /// The remote address associated with this request.
    var remoteAddress: SocketAddress? { get }
    /// A set of arbitrary information that is associated with this request.
    var information: Set<AnyInformation> { get }
}

/// A default implementation of ``RequestBasis`` that can be constructed from
/// its components.
public struct DefaultRequestBasis: RequestBasis {
    private let _description: String?
    private let _debugDescription: String?
    
    public let remoteAddress: SocketAddress?
    public let information: Set<AnyInformation>
    
    public var description: String {
        _description ?? "Request(remoteAddress: \(remoteAddress?.description ?? "nil"), information: \(information))"
    }
    
    public var debugDescription: String {
        _debugDescription ?? "DefaultRequestBasis(remoteAddress: \(remoteAddress?.description ?? "nil"), information: \(information))"
    }
    
    /// Construct a ``DefaultRequestBasis`` from its components.
    public init(description: String? = nil,
                debugDescription: String? = nil,
                remoteAddress: SocketAddress? = nil,
                information: Set<AnyInformation> = []) {
        self._description = description
        self._debugDescription = debugDescription
        self.remoteAddress = remoteAddress
        self.information = information
    }
    
    /// Construct a ``DefaultRequestBasis`` from a given `remoteAddress` and `information`.
    /// This initializer uses the `base` object  to derive its ``DefaultRequestBasis/description`` and
    /// ``DefaultRequestBasis/debugDescription`` properties.
    public init(base: Any,
                remoteAddress: SocketAddress? = nil,
                information: Set<AnyInformation> = []) {
        self.init(description: (base as? CustomStringConvertible)?.description ?? "\(base)",
                  debugDescription: (base as? CustomDebugStringConvertible)?.debugDescription ?? "\(base)",
                  remoteAddress: remoteAddress,
                  information: information)
    }
}


// MARK: Request Decoding

extension DecodingStrategy {
    /// Generates an Apodini `Request` based on the given `basis` and `eventLoop` which lazily decodes
    /// the given `input` by applying this strategy.
    ///
    /// When working with a `Publisher` pipeline, use `Publisher`'s `decode(using:with)`.
    ///
    /// - Parameters:
    ///     - `input`:  The ``DecodingStrategy/Input`` this strategy can decode parameter from
    ///     - `basis`: The further information that is needed next to parameter retrieval and the `eventLoop` that are required to build an Apodini `Request`
    ///     - `eventLoop`: The `EventLoop` this `Request` is to be evaluated on
    public func decodeRequest(from input: Input, with basis: RequestBasis, with eventLoop: EventLoop) -> DecodingRequest<Input> {
        DecodingRequest(basis: basis, input: input, strategy: self.typeErased, eventLoop: eventLoop)
    }
    
    /// A shortcut for ``DecodingStrategy/decodeRequest(from:with:with:)`` for ``DecodingStrategy``s where
    /// ``DecodingStrategy/Input`` conforms to ``RequestBasis``.
    ///
    /// When working with a `Publisher` pipeline, use `Publisher`'s `decode(using:with)`.
    ///
    /// - Parameters:
    ///     - `input`:  The ``DecodingStrategy/Input`` this strategy can decode parameter from, which also serves as the ``RequestBasis``
    ///     - `eventLoop`: The `EventLoop` this `Request` is to be evaluated on
    public func decodeRequest(from input: Input, with eventLoop: EventLoop) -> DecodingRequest<Input> where Input: RequestBasis {
        self.decodeRequest(from: input, with: input, with: eventLoop)
    }
}

extension Publisher {
    /// Maps each incoming `Output` to an Apodini `Request` based on the given `strategy` by
    /// calling the strategy's ``DecodingStrategy/decodeRequest(from:with:with:)`` function.
    ///
    /// The `Output` must be a tuple consisting of a ``RequestBasis`` and the ``DecodingStrategy/Input`` for `S`.
    ///
    /// - Parameters:
    ///     - `strategy`:  The ``DecodingStrategy`` that is required to retrieve parameters from the according ``DecodingStrategy/Input``
    ///     contained in the second element of each value published on this `Publisher`
    ///     - `eventLoop`: The `EventLoop` this `Request` is to be evaluated on
    public func decode<S: DecodingStrategy, R: RequestBasis>(using strategy: S, with eventLoop: EventLoop)
        -> OpenCombine.Publishers.Map<Self, DecodingRequest<S.Input>> where Output == (R, S.Input) {
        self.map { requestBasis, input in
            strategy.decodeRequest(from: input, with: requestBasis, with: eventLoop)
        }
    }
    
    /// Maps each incoming `Output` to an Apodini `Request` based on the given `strategy` by
    /// calling the strategy's ``DecodingStrategy/decodeRequest(from:with:)`` function.
    ///
    /// - Parameters:
    ///     - `strategy`:  The ``DecodingStrategy`` that is required to retrieve parameters from the according ``DecodingStrategy/Input``
    ///     contained in the second element of each value published on this `Publisher`
    ///     - `eventLoop`: The `EventLoop` this `Request` is to be evaluated on
    public func decode<S: DecodingStrategy>(using strategy: S, with eventLoop: EventLoop)
        -> OpenCombine.Publishers.Map<Self, DecodingRequest<S.Input>> where Output == S.Input, S.Input: RequestBasis {
        self.map { input in
            strategy.decodeRequest(from: input, with: eventLoop)
        }
    }
}

/// A ``RequestBasis`` based Apodini `Request` which uses a ``DecodingStrategy``
/// as well as an instance of its ``DecodingStrategy/Input`` type to implement its
/// ``DecodingRequest/retrieveParameter(_:)`` function.
public struct DecodingRequest<Input>: Request {
    let basis: RequestBasis
    
    let input: Input
    
    let strategy: AnyDecodingStrategy<Input>
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
        try strategy.strategy(for: parameter)
            .decode(from: input)
    }
    
    public let eventLoop: EventLoop
    
    public var description: String {
        basis.description
    }
    
    public var debugDescription: String {
        basis.debugDescription
    }
    
    public var remoteAddress: SocketAddress? {
        basis.remoteAddress
    }
    
    public var information: Set<AnyInformation> {
        basis.information
    }
}
