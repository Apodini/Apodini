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

public protocol RequestBasis {
    /// Returns a description of the Request.
    var description: String { get }
    /// Returns a debug description of the Request.
    var debugDescription: String { get }

    var remoteAddress: SocketAddress? { get }
    
    var information: Set<AnyInformation> { get }
}

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
    
    public init(description: String? = nil,
                debugDescription: String? = nil,
                remoteAddress: SocketAddress? = nil,
                information: Set<AnyInformation> = []) {
        self._description = description
        self._debugDescription = debugDescription
        self.remoteAddress = remoteAddress
        self.information = information
    }
    
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
    public func decodeRequest(from input: Input, with basis: RequestBasis, with eventLoop: EventLoop) -> DecodingRequest<Input> {
        DecodingRequest(basis: basis, input: input, strategy: self.typeErased, eventLoop: eventLoop)
    }
}

extension Publisher {
    public func decode<S: DecodingStrategy, R: RequestBasis>(using strategy: S, with eventLoop: EventLoop) -> OpenCombine.Publishers.Map<Self, DecodingRequest<S.Input>> where Output == (R, S.Input) {
        self.map { (requestBasis, input) in
            strategy.decodeRequest(from: input, with: requestBasis, with: eventLoop)
        }
    }
}

public struct DecodingRequest<Input>: Request {
    let basis: RequestBasis
    
    public let input: Input // TODO: make internal
    
    let strategy: AnyDecodingStrategy<Input>
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
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














