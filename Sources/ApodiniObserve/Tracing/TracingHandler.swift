//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Tracing

struct TracingHandler<H: Handler>: Handler {
    /// The delegated `Handler`
    let delegate: Delegate<H>

    @Environment(\.connection)
    var connection

    @ObserveMetadata
    var observeMetadata // TODO: Maybe only get the blackboard metadata to reduce performance impact

    @Environment(\.instrument)
    var instrument

    @Environment(\.tracer)
    var tracer

    init(_ handler: H) {
        self.delegate = Delegate(handler, .required)
    }

    func handle() async throws -> H.Response {
        // Extract context from HTTP headers
        // e.g. OTel's W3CPropagator handles extracting W3C context propagation headers
        var baggage = Baggage.topLevel
        instrument.extract(connection.information, into: &baggage, using: HTTPInformationExtractor())

        let span = tracer.startSpan(getOperationName(), baggage: baggage, ofKind: .server)
        defer { span.end() }

        setEndpointMetadata(to: span)

        do {
            return try await delegate
                .environmentObject(span.baggage)
                .instance()
                .handle()

            // TODO: Can we get the response status here somehow

            // TODO: Inject baggage into headers
//            instrument.inject(span.baggage, into: &<#T##Carrier#>, using: HTTPInformationExtractor())
        } catch {
            span.recordError(error)
            throw error // rethrow for InterfaceExporter handling
        }
    }

    private func getOperationName() -> String {
        "\(observeMetadata.blackboardMetadata.operation.description) \(observeMetadata.blackboardMetadata.endpointName)"
    }

    private func setEndpointMetadata(to span: Span) {
        span.attributes.apodini.endpointName = observeMetadata.blackboardMetadata.endpointName
        span.attributes.apodini.endpointOperation = observeMetadata.blackboardMetadata.operation.description
        span.attributes.apodini.endpointPath = String(
            observeMetadata.blackboardMetadata.endpointPathComponents.value
                .reduce(into: "") { path, endpointPath in
                    path.append(contentsOf: endpointPath.description + "/")
                }
                .dropLast()
        )
        span.attributes.apodini.endpointCommunicationalPattern = observeMetadata.blackboardMetadata.communicationalPattern.rawValue
        span.attributes.apodini.endpointVersion = observeMetadata.blackboardMetadata.context.get(valueFor: APIVersionContextKey.self)?.debugDescription ?? "unknown"
    }
}

struct TracingHandlerInitializer: DelegatingHandlerInitializer {
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Never> {
        SomeHandler(TracingHandler(delegate))
    }
}
