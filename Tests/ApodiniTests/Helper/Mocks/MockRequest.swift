//
// Created by Andi on 25.12.20.
//

import XCTest
import Foundation
@testable import Apodini


enum MockRequest {
    static func createRequest(
        running eventLoop: EventLoop,
        queuedParameters parameterValues: Any??...
    ) -> ValidatedRequest<MockExporter<String>, EmptyHandler> {
        createRequest(on: EmptyHandler(), running: eventLoop, queuedParameters: parameterValues)
    }

    static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        queuedParameters parameterValues: Any??...
    ) -> ValidatedRequest<MockExporter<String>, H> {
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
        
        do {
            return try validator.validate("Undefined Exporter Request", with: eventLoop)
        } catch {
            XCTFail("Validating MockRequest failed. The provided queuedParameters seem to be invalid.")
            exit(1)
        }
    }
}
