//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniUtils
import ApodiniNetworking


//public protocol AnyEncoder: ApodiniUtils.AnyEncoder {}

// TODO Is this REST-specific? No?? Move to Utils or Networking!

/// Default implementation of the `ContentEncoder` protocol that sets the appropriate content type if possible
extension AnyEncoder {
    /// Encodes the given object which conform to `Encodable` into the `Bytebuffer`
    /// - Parameters:
    ///    - encodable: The to be encoded object
    ///    - to: The ByteBuffer to encode to
    ///    - headers: The HTTP header to set the content type
    public func encode<T: Encodable>(_ value: T, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws { // TOOD what about HTTP2 headers???
        if let mediaType = self.resultMediaType {
            headers[.contentType] = mediaType
        }
        try body.writeBytes(self.encode(value))
    }
}

//public protocol AnyDecoder: ApodiniUtils.AnyDecoder {}

/// Default implementation of the `ContentDecoder` protocol
extension AnyDecoder {
    /// Decodes the given object which conform to `Decodable` from the `Bytebuffer`
    /// - Parameters:
    ///    - decodable: The type of the to be decoded object
    ///    - to: The ByteBuffer to encode from
    ///    - headers: The HTTP header to get the content type
    public func decode<T: Decodable>(_: T.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> T {
        // TODO this doesn't use the headers parameter at all!????
        let data = body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()
        return try self.decode(T.self, from: data)
    }
}

//extension JSONEncoder: AnyEncoder {}
//extension JSONDecoder: AnyDecoder {}
