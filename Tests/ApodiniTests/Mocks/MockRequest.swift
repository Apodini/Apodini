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
    ) -> ValidatedRequest<MockExporter<String>, EmptyHandler> {
        createRequest(on: EmptyHandler(), running: eventLoop, database: database, queuedParameters: parameterValues)
    }

    static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        database: Database? = nil,
        queuedParameters parameterValues: Any??...
    ) -> ValidatedRequest<MockExporter<String>, H> {
        createRequest(on: handler, running: eventLoop, database: database, queuedParameters: parameterValues)
    }

    private static func createRequest<H: Handler>(
        on handler: H,
        running eventLoop: EventLoop,
        database: Database? = nil,
        queuedParameters parameterValues: [Any??]
    ) -> ValidatedRequest<MockExporter<String>, H> {
        let exporter = MockExporter<String>(queued: parameterValues)
        
        let endpoint = handler.mockEndpoint()
        
        var validator = endpoint.validator(for: exporter)
        
        // swiftlint:disable:next force_unwrapping
        let databaseClosure = database != nil ? { database! } : nil
        
        return try! validator.validate("Undefined Exporter Request", with: (eventLoop, databaseClosure))
    }
}
