//
//  Evaluation.swift
//  
//
//  Created by Max Obermeier on 22.06.21.
//

import Apodini

public extension Request {
    func evaluate<H: Handler>(on handler: H) throws -> H.Response {
        try Delegate<H>.standaloneInstance(of: handler).evaluate(using: self)
    }
}

internal extension Delegate where D: Handler {
    static func standaloneInstance<H: Handler>(of delegate: H) -> Delegate<H> {
        return IE.standaloneDelegate(delegate)
    }
    
    func evaluate(using request: Request) throws -> D.Response {
        try IE.evaluate(delegate: self, using: request)
    }
}
