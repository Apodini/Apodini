import XCTest
@testable import Apodini

func mockQuery<Value: Encodable, H: Handler>(component: H, value: Value.Type, app: Application, queued parameterValues: Any??...) throws -> Value? {
    let endpoint = component.mockEndpoint(app: app)
    let exporter = MockExporter<String>(queued: parameterValues)
    var context = endpoint.createConnectionContext(for: exporter)

   let response = try context.handle(request: "Mock Request", eventLoop: app.eventLoopGroup.next())
        .wait()
    
    guard case let .final(result) = response.typed(value) else {
        XCTFail("Expected return value to be wrapped in Action.final by default")
        return nil
    }
    
    return result
}
