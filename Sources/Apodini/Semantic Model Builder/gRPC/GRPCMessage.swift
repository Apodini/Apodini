//
//  GRPCMessage.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation
@_implementationOnly import Vapor

class GRPCMessage: Apodini.ExporterRequest {
    internal var data: Data
    var length: Int

    init(from data: Data, length: Int) {
        self.data = data
        self.length = length
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
