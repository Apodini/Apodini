//
//  GRPCMessage.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation
import Apodini

/// gRPC message
public final class GRPCMessage: Apodini.ExporterRequest {
    /// Default message that can be used to call handlers in cases
    /// where no input message was provided.
    /// Content is empty, length is zero, and the compressed flag is not set.
    static let defaultMessage = GRPCMessage(from: Data(), length: 0, compressed: false)

    internal var data: Data
    var length: Int
    var compressed: Bool

    init(from data: Data, length: Int, compressed: Bool) {
        self.data = data
        self.length = length
        self.compressed = compressed
    }

    var didCollectAllFragments: Bool {
        data.count >= length
    }

    func append(data: Data) {
        self.data.append(data)
    }
}
