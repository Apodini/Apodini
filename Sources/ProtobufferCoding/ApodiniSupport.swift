//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniNetworkingHTTPSupport


/// The Protocol Buffers package used for Apodini-specific supporting helper types.
public let apodiniSupportProtoPackage = ProtobufPackageUnit(packageName: "ApodiniSupport", filename: "apodini/ApodiniSupport.proto")

/// A Protocol Buffers-compatible struct for encoding and decoding `Apodini.Blob` objects.
/// - Note: This type is used internally within ProtobufferCoding, and should not be used by external clients.
///         Simply pass `Apodini.Blob` objects, or decode `Apodini.Blob.self` via the `ProtobufferDecoder`, and the types will automatically be handled correctly.
public struct ApodiniBlob: Codable, ProtobufMessage, ProtoTypeInPackage {
    public static let package = apodiniSupportProtoPackage
    public let data: Data
    public let mediaType: HTTPMediaType?
    
    public init(data: Data, mediaType: HTTPMediaType?) {
        self.data = data
        self.mediaType = mediaType
    }
    
    public init(blob: Blob) {
        self.data = Data(buffer: blob.byteBuffer)
        self.mediaType = blob.type
    }
    
    public func asApodiniBlob() -> Apodini.Blob {
        Blob(data, type: mediaType)
    }
}

extension HTTPMediaType: ProtoTypeInPackage {
    public static let package = apodiniSupportProtoPackage
}
