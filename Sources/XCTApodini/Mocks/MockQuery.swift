import XCTest
@testable import Apodini

public func mockQuery<Value: Encodable, H: Handler>(
    component: H,
    value: Value.Type,
    app: Application,
    queued parameterValues: Any??...
) throws -> Response<Value> {
    let endpoint = component.mockEndpoint(app: app)
    let exporter = MockExporter<String>(queued: parameterValues)
    let context = endpoint.createConnectionContext(for: exporter)

    let response = try context.handle(request: "Mock Request", eventLoop: app.eventLoopGroup.next())
        .wait()
    
    return try XCTUnwrap(response.typed(value))
}
