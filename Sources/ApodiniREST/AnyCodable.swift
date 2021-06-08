//
//  AnyCodable.swift
//  
//
//  Created by Philipp Zagar on 08.06.21.
//

import Foundation
import ApodiniUtils
import Vapor

public protocol AnyEncoder: ApodiniUtils.AnyEncoder, ContentEncoder {}

/// Default implementation of the `ContentEncoder` protocol that sets the content type to JSON
extension AnyEncoder {
    /**
     Encodes the given object which conform to `Encodable` into the `Bytebuffer`
     - Parameters:
        - encodable: The to be encoded object
        - to: The ByteBuffer to encode to
        - headers: The HTTP header to set the content type
     */
    public func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws where E: Encodable {
        headers.contentType = .json
        try body.writeBytes(self.encode(encodable))
    }
}

public protocol AnyDecoder: ApodiniUtils.AnyDecoder, ContentDecoder {}

/// Default implementation of the `ContentDecoder` protocol
extension AnyDecoder {
    /**
     Decodes the given object which conform to `Decodable` from the `Bytebuffer`
     - Parameters:
        - decodable: The type of the to be decoded object
        - to: The ByteBuffer to encode from
        - headers: The HTTP header to get the content type
     */
    public func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D: Decodable {
        let data = body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()
        return try self.decode(D.self, from: data)
    }
}

extension JSONEncoder: AnyEncoder {}

extension JSONDecoder: AnyDecoder {}
