//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO
import Apodini
import ApodiniExtension
import Logging

/// gRPC message
public final class GRPCMessage {
    /// Default message that can be used to call handlers in cases
    /// where no input message was provided.
    /// Content is empty, length is zero, and the compressed flag is not set.
    static let defaultMessage = GRPCMessage(from: Data(), length: 0, compressed: false, remoteAddress: nil)

    internal var data: Data
    var length: Int
    var compressed: Bool
    let remoteAddress: SocketAddress?
    
    public var loggingMetadata: Logger.Metadata {
        [
            "data": self.data.count <= 32_768 ? .string(self.data.base64EncodedString()) : .string("\(self.data.base64EncodedString().prefix(32_715))... (Further bytes omitted since data too large!)"),
            "length": .string(self.length.description),
            "compressed": .string(self.compressed.description)
        ]
    }

    init(from data: Data, length: Int, compressed: Bool, remoteAddress: SocketAddress?) {
        self.data = data
        self.length = length
        self.compressed = compressed
        self.remoteAddress = remoteAddress
    }

    var didCollectAllFragments: Bool {
        data.count >= length
    }

    func append(data: Data) {
        self.data.append(data)
    }
}
