//
// Created by Andi on 25.12.20.
//

import Foundation
import protocol NIO.EventLoop
@testable import Apodini


enum MockRequest {
    static func createRequest(
            running eventLoop: EventLoop,
            queuedParameters parameterValues: Any...
    ) -> Request<MockExporter<String>, EmptyComponent> {
        createRequest(on: EmptyComponent(), running: eventLoop, queuedParameters: parameterValues)
    }

    static func createRequest<C: Component>(
            on component: C,
            running eventLoop: EventLoop,
            queuedParameters parameterValues: Any...
    ) -> Request<MockExporter<String>, C> {
        let endpoint = component.mockEndpoint()
        let exporter = MockExporter<String>(queued: parameterValues)
        return Request(for: exporter, with: "Undefined Exporter Request", on: endpoint, running: eventLoop)
    }
}
