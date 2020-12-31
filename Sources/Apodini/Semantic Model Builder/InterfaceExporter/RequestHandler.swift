//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import protocol FluentKit.Database

class EndpointRequestHandler<I: InterfaceExporter> {
    func callAsFunction(request: I.ExporterRequest, eventLoop: EventLoop, database: Database? = nil) -> EventLoopFuture<Encodable> {
        // We are doing nothing here. Everything is handled in InternalEndpointRequestHandler
        fatalError("EndpointRequestHandler.handleRequest() was not overridden. EndpointRequestHandler must not be created manually!")
    }
}

extension EndpointRequestHandler where I.ExporterRequest: WithEventLoop {
    func callAsFunction(request: I.ExporterRequest) -> EventLoopFuture<Encodable> {
        callAsFunction(request: request, eventLoop: request.eventLoop)
    }
}

class InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler>: EndpointRequestHandler<I> {
    private var endpoint: Endpoint<H>
    private var exporter: I

    init(endpoint: Endpoint<H>, exporter: I) {
        self.endpoint = endpoint
        self.exporter = exporter
    }

    override func callAsFunction(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        database: Database? = nil
    ) -> EventLoopFuture<Encodable> {
        let databaseClosure: (() -> Database)?
        if let database = database {
            databaseClosure = { database }
        } else if let requestWithDatabase = exporterRequest as? WithDatabase {
            databaseClosure = requestWithDatabase.database
        } else {
            databaseClosure = nil
        }

        let request = ApodiniRequest(for: exporter, with: exporterRequest, on: endpoint, running: eventLoop, database: databaseClosure)

        let guardEventLoopFutures = endpoint.guards.map { guardClosure -> EventLoopFuture<Void> in
            do {
                return try request.enterRequestContext(with: guardClosure()) { requestGuard in
                    do {
                        return try requestGuard.executeGuardCheck(on: request)
                    } catch {
                        return eventLoop.makeFailedFuture(error)
                    }
                }
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }

        return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: eventLoop)
                .flatMap { _ in
                    do {
                        return try request.enterRequestContext(with: self.endpoint.component) { component in
                            do {
                                var response: Encodable = component.handle()

                                for transformer in self.endpoint.responseTransformers {
                                    response = try request.enterRequestContext(with: transformer()) { responseTransformer in
                                        responseTransformer.transform(response: response)
                                    }
                                }

                                return eventLoop.makeSucceededFuture(response)
                            } catch {
                                return eventLoop.makeFailedFuture(error)
                            }
                        }
                    } catch {
                        return eventLoop.makeFailedFuture(error)
                    }
                    return eventLoop.makeSucceededFuture(response)
                }
            }
    }
}
