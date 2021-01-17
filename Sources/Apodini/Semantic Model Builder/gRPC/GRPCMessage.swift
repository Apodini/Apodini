//
//  GRPCMessage.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation

class GRPCMessage: Apodini.ExporterRequest {
    /// Default message  that can be used to call handlers in cases
    /// where no input message was provided.
    /// Content is empty, length is zero, and the compressed flag is not set.
    static let DefaultMessage = GRPCMessage(from: Data(), length: 0, compressed: false)

    internal var data: Data
    var length: Int
    var compressed: Bool

    init(from data: Data, length: Int, compressed: Bool) {
        self.data = data
        self.length = length
        self.compressed = compressed
    }

    /// TRUE if all fragments for this message have been collected.
    /// FALSE othwise.
    var isComplete: Bool {
        if data.count < length {
            return false
        } else {
            return true
        }
    }

    func append(data: Data) {
        self.data.append(data)
    }
}
