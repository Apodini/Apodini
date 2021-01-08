//
//  GRPCRequest.swift
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
        if (data.count < length) {
            return false
        } else {
            return true
        }
    }

    func append(data: Data) {
        self.data.append(data)
    }
}

/// The request that is used  by Aponini's `GRPCInterfaceExporter`.
//class GRPCRequest: Apodini.ExporterRequest {
//    internal var bodyData: Data
//
//    /// The messages that are contained in this GRPC request.
//    /// One GRPC request can hold many messages,
//    /// but one message can also span mutliple requests.
//    internal var messages: [Data]
//
//    init(from request: Vapor.Request) {
//        self.internalRequest = request
//    }
//
//    /// A GRPC message can be delivered via multiple HTTP requests.
//    /// If this request is the last frame of the GRPC message it belongs to,
//    /// `isLastFragment` is `true`.
//    /// Otherwise, this property is false.
//    var isLastFragment: Bool {
//        false
//    }
//
//    func drain(_ handler: @escaping (BodyStreamResult) -> EventLoopFuture<Void>) {
//        internalRequest.body.drain(handler)
//    }
//}
//
//// MARK: GRPCRequest + Reducible
//extension GRPCRequest: Reducible {
//    func reduce(to new: GRPCRequest) -> Self {
//
//    }
//}
