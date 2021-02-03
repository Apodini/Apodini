import XCTest
@testable import Apodini

func mockQuery<Value: Encodable, H: Handler>(component: H, value: Value.Type, app: Application, queued parameterValues: Any??...) throws -> Value? {
    let endpoint = component.mockEndpoint(app: app)
    let exporter = MockExporter<String>(queued: parameterValues)
    let context = endpoint.createConnectionContext(for: exporter)

    let response = try context.handle(request: "Mock Request", eventLoop: app.eventLoopGroup.next())
        .wait()
    
    let typedResponse = try XCTUnwrap(response.typed(value))
    XCTAssertEqual(typedResponse.connectionEffect, .close, "Expected a response with a `ConnectionEffect` if `.close` by default")
    
    return typedResponse.content
}
