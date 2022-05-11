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
/// A `Handler` used to automatically trace other `Handler`s.
    /// The delegated `Handler`
    let delegate: Delegate<H>

    @Environment(\.connection)
    var connection

    @Environment(\ObserveMetadataExporter.SharedRepositoryObserveMetadata.value)
    var sharedRepositoryMetadata

    /// Logging metadata is only accessed in case of a server error.
    @LoggingMetadata
    var loggingMetadata

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
        // We need to use the instrument here because the tracer variable tracer is only the first available `Tracer` instance
        // and we might want to extract baggage from other instruments as well.
        instrument.extract(connection.information, into: &baggage, using: HTTPInformationExtractor())

        let span = tracer.startSpan(getOperationName(), baggage: baggage, ofKind: .server)
        defer { span.end() }

        setEndpointMetadata(to: span)

        do {
            return try await delegate
                .environmentObject(span)
                .instance()
                .handle()

            // it would be great to get the response status here
            // to set it as a Span attribute
        } catch {
            setErrorMetadata(to: span, for: error)
            throw error // rethrow for InterfaceExporter handling
        }
    }

    private func getOperationName() -> String {
        "\(sharedRepositoryMetadata.operation.description) \(sharedRepositoryMetadata.endpointName)"
    }

    private func setEndpointMetadata(to span: Span) {
        span.attributes.apodini.endpointName = sharedRepositoryMetadata.endpointName
        span.attributes.apodini.endpointOperation = sharedRepositoryMetadata.operation.description
        span.attributes.apodini.endpointPath = String(
            sharedRepositoryMetadata.endpointPathComponents.value
                .reduce(into: "") { path, endpointPath in
                    path.append(contentsOf: endpointPath.description + "/")
                }
                .dropLast()
        )
        span.attributes.apodini.endpointCommunicationalPattern = sharedRepositoryMetadata.communicationPattern.rawValue
        span.attributes.apodini.endpointVersion = sharedRepositoryMetadata.context.get(
            valueFor: APIVersionContextKey.self
        )?.debugDescription ?? "unknown"
    }

    private func setErrorMetadata(to span: Span, for error: Error) {
        // Tracers need to convert an Error to a String to record it. The OTel implementation uses String(describing:) internally.
        // Because ApodiniError currently doesn't conform to CustomStringConvertible/CustomDebugStringConvertible,
        // this results in a quite an ugly string representation in the trace.
        span.recordError(error)
        span.setStatus(.init(code: .error, message: error.standardMessage))

        // We only use expensive loggingMetadata in case of a "server error"
        guard error.apodiniError.shouldCollectErrorMetadata else {
            return
        }

        for metadataKey in ["request", "information"] {
            guard let metadataValue = loggingMetadata[metadataKey] else { continue }
            span.attributes.merge(metadataValue.spanAttributes(key: "apodini.\(metadataKey)"))
        }
    }
}

struct TracingHandlerInitializer: DelegatingHandlerInitializer {
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Never> {
        SomeHandler(TracingHandler(delegate))
    }
}

extension ApodiniError {
    var shouldCollectErrorMetadata: Bool {
        switch option(for: .errorType) {
        case .serverError, .notAvailable, .other:
            // These errors are caused by unexpected behavior of the service (correspond to HTTP 5xx)
            // or are non-ApodiniErrors
            return true
        default:
            // The remaining errors are caused by the client (correspond to HTTP 4xx)
            return false
        }
    }
}
