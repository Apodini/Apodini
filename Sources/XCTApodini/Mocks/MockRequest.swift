//
// Created by Andreas Bauer on 25.12.20.
//

#if DEBUG || RELEASE_TESTING
import XCTest
import Foundation
@testable import Apodini


/// A namespace for methods that generate `ValidatedRequest`s from mock data.
public enum MockRequest {
    /// Create a request on an `EmptyHandler`
    public static func createRequest(
        running eventLoop: EventLoop,
        queuedParameters parameterValues: Any??...
    ) -> ValidatingRequest<MockExporter<String>, EmptyHandler> {
        createRequest(on: EmptyHandler(), running: eventLoop, queuedParameters: parameterValues)
    }

    /// Create a request on `handler`
    public static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        queuedParameters parameterValues: Any??...
    ) -> ValidatingRequest<MockExporter<String>, H> {
        createRequest(on: handler, running: eventLoop, queuedParameters: parameterValues)
    }

    private static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        queuedParameters parameterValues: [Any??]
    ) -> ValidatingRequest<MockExporter<String>, H> {
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
#endif
