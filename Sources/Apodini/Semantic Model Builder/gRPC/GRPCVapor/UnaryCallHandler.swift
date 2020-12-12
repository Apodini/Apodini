//
//  File.swift
//  
//
//  Created by Moritz Schüll on 18.11.20.
//

import Foundation
import Vapor


// Stripped down version of an AnyCallHandler implementation
// I want to keep it simple to help my understanding process
class UnaryCallHandler: AnyCallHandler {

    var vaporRequest: Vapor.Request
    var response: EventLoopFuture<Vapor.Response>

    init(request: Vapor.Request, response: EventLoopFuture<Vapor.Response>) {
        self.vaporRequest = request
        self.response = response
    }
}
