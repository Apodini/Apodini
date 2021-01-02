//
// Created by Andi on 25.12.20.
//

import Foundation
import protocol NIO.EventLoop
import protocol FluentKit.Database
@testable import Apodini


enum MockRequest { 
    static func createRequest(
        running eventLoop: EventLoop,
        queuedParameters parameterValues: Any??...
    ) -> ApodiniRequest<MockExporter<String>, EmptyHandler> {
        createRequest(on: EmptyHandler(), running: eventLoop, queuedParameters: parameterValues)
    }

    static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        queuedParameters parameterValues: Any??...
    ) -> ApodiniRequest<MockExporter<String>, H> {
        createRequest(on: handler, running: eventLoop, queuedParameters: parameterValues)
    }

    private static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        queuedParameters parameterValues: [Any??]
    ) -> ValidatedRequest<MockExporter<String>, H> {
        let exporter = MockExporter<String>(queued: parameterValues)
        
        let endpoint = handler.mockEndpoint()
        
        var validator = endpoint.validator(for: exporter)
        
        return try! validator.validate("Undefined Exporter Request", with: (eventLoop, nil))
    }
}
