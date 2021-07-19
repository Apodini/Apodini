#if DEBUG || RELEASE_TESTING
import XCTest
@testable import Apodini
import ApodiniExtension

/// Evaluates the given `handler` on the given `app` using the given `parameterValues`.
public func mockQuery<Value: Encodable, H: Handler>(
    handler: H,
    value: Value.Type,
    app: Application,
    final: Bool = false,
    queued parameterValues: Any??...
) throws -> Response<Value> {
    var handler = handler
    Apodini.inject(app: app, to: &handler)
    
    let endpoint = handler.mockEndpoint(app: app)
    let exporter = MockExporter<String>(queued: parameterValues)
    
    var delegate = Delegate(handler, .required)
    delegate.activate()
    
    let request = "Mock Request"
    
    let response: Response<H.Response.Content> = try InterfaceExporterLegacyStrategy(exporter)
                                                    .applied(to: endpoint)
                                                    .decodeRequest(from: request,
                                                                   with: DefaultRequestBasis(base: request),
                                                                   with: app.eventLoopGroup.next())
                                                    .insertDefaults(with: endpoint[DefaultValueStore.self])
                                                    .evaluate(on: delegate, final ? .end : .open)
                                                    .wait()
    
    return try XCTUnwrap(response.typed(value))
}
#endif
