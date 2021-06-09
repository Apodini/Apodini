#if DEBUG || RELEASE_TESTING
import XCTest
@testable import Apodini

/// Evaluates the given `handler` on the given `app` using the given `parameterValues`.
public func mockQuery<Value: Encodable, H: Handler>(
    handler: H,
    value: Value.Type,
    app: Application,
    queued parameterValues: Any??...
) throws -> Response<Value> {
    let endpoint = handler.mockEndpoint(app: app)
    let exporter = MockExporter<String>(queued: parameterValues)
    let context = endpoint.createConnectionContext(for: exporter)

    let response = try context.handle(request: "Mock Request", eventLoop: app.eventLoopGroup.next())
        .wait()
    
    return try XCTUnwrap(response.typed(value))
}
#endif
