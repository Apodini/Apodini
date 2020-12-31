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
        database: Database? = nil,
        queuedParameters parameterValues: Any??...
    ) -> ApodiniRequest<MockExporter<String>, EmptyHandler> {
        createRequest(on: EmptyHandler(), running: eventLoop, database: database, queuedParameters: parameterValues)
    }

    static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        database: Database? = nil,
        queuedParameters parameterValues: Any??...
    ) -> ApodiniRequest<MockExporter<String>, H> {
        createRequest(on: handler, running: eventLoop, database: database, queuedParameters: parameterValues)
    }

    private static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        database: Database? = nil,
        queuedParameters parameterValues: [Any??]
    ) -> ApodiniRequest<MockExporter<String>, H> {
        let endpoint = handler.mockEndpoint()
        let exporter = MockExporter<String>(queued: parameterValues)
        // swiftlint:disable:next force_unwrapping
        let databaseClosure = database != nil ? { database! } : nil
        return ApodiniRequest(for: exporter, with: "Undefined Exporter Request", on: endpoint, running: eventLoop, database: databaseClosure)
    }
}
