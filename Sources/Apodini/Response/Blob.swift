//
//  Blob.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import NIO
import NIOFoundationCompat


public struct Blob: Encodable {
    enum CodingKeys: String, CodingKey {
        case byteBuffer
        case type
    }
    
    
    public let byteBuffer: ByteBuffer
    public let type: MimeType?
    
    
    public init(_ byteBuffer: ByteBuffer, type: MimeType? = nil) {
        self.byteBuffer = byteBuffer
        self.type = type
    }
    
    
    public func encode(to encoder: Encoder) throws {
        print(
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
