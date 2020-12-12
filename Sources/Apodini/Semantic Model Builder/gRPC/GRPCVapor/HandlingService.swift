//
//  HandlingService.swift
//  
//
//  Created by Moritz Schüll on 18.11.20.
//
//  Provides a gRPC service for an Apodini handling compontent (according to terminology as used in Max' proposal https://gist.github.com/theMomax/85c5cf3fbc140ec17b89647b7558929c)
//
//

import Foundation
import Vapor


class HandlingService: GRPCService {
    var serviceName: String
    var requestHandler: (Vapor.Request) -> EventLoopFuture<Response>


    init(name: String, requestHandler: @escaping (Vapor.Request) -> EventLoopFuture<Response>) {
        self.serviceName = name
        self.requestHandler = requestHandler
    }

    func handleMethod(methodName: String, vaporRequest: Vapor.Request) -> AnyCallHandler? {

        #if DEBUG
        print("Service \(serviceName) is called for method \(methodName)")
        #endif

        // TODO methodName is ignored at the moment

        let response = requestHandler(vaporRequest)
        return UnaryCallHandler(request: vaporRequest, response: response)
    }
}
