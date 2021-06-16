//
//  Blob.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import NIO
import Foundation
import NIOFoundationCompat


/// A binary large object (blob) that can be used to return binary data from a `Handler`
public struct Blob: Encodable, ResponseTransformable {
    enum CodingKeys: String, CodingKey {
        case byteBuffer
        case type
    }
    
    
    /// The `ByteBuffer` representation of the `Blob`
    public let byteBuffer: ByteBuffer
    /// The MIME type associated with the `Blob`
    public let type: MimeType?
    
    
    /// - Parameters:
    ///   - data: The `Data` representation of the `Blob`
    ///   - type: The MIME type associated with the `Blob`
    public init(_ data: Data, type: MimeType? = nil) {
        self.init(ByteBuffer(data: data), type: type)
    }
    
    
    /// - Parameters:
    ///   - byteBuffer: The `ByteBuffer` representation of the `Blob`
    ///   - type: The MIME type associated with the `Blob`
    public init(_ byteBuffer: ByteBuffer, type: MimeType? = nil) {
        self.byteBuffer = byteBuffer
        self.type = type
    }
    
    
    public func encode(to encoder: Encoder) throws {
        Application.logger.debug(
            """
            Information: The used Exporter currently doesn't support Blob's as a content of an Apodini Reponse.
            The data and mime type will be encoded according to the data encoding strategy passed by the Encoder.
            """
        )
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes), forKey: .byteBuffer)
        try container.encode(type, forKey: .type)
    }
}
