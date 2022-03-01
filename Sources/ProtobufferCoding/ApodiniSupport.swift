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


public let apodiniSupportProtoPackage = ProtobufPackageUnit(packageName: "ApodiniSupport", filename: "apodini/ApodiniSupport.proto")

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

