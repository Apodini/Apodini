//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
import Foundation
//import class Vapor.Application
//simport class Vapor.Request
import ApodiniExtension
import ApodiniUtils

public class EmptyRequest: RequestBasis {
    public var description: String {
        String(describing: self)
    }
    public var debugDescription: String {
        description
    }
    public var remoteAddress: SocketAddress?

    public var information: InformationSet

    public var parameters: [Any??]

    public init(information: AnyInformation..., parameters: Any??...) {
        self.information = InformationSet(information)
        self.parameters = parameters
    }
}

open class MockExporter<Request>: LegacyInterfaceExporter {
    struct EndpointRepresentation {
        let endpoint: AnyEndpoint
        let evaluateCallback: (_ request: Request, _ parameters: [Any??], _ app: Apodini.Application) throws -> Response<AnyEncodable>

        internal init(_ endpoint: AnyEndpoint,
                      _ evaluateCallback: @escaping (Request, [Any??], Apodini.Application) throws -> Response<AnyEncodable>) {
            self.endpoint = endpoint
            self.evaluateCallback = evaluateCallback
        }
    }

    var parameterValues: [Any??] = []
    
    let onExport: (AnyEndpoint) -> Void
    let onFinished: (WebServiceModel) -> Void

    var endpoints: [EndpointRepresentation] = []

    /// Creates a new MockExporter which uses the passed parameter values as FIFO queue on retrieveParameter
    public init(queued parameterValues: Any??...,
                calling onExport: @escaping (AnyEndpoint) -> Void = { _ in },
                onFinished: @escaping (WebServiceModel) -> Void = { _ in }) {
        self.parameterValues = parameterValues
        self.onExport = onExport
        self.onFinished = onFinished
    }

    // See https://bugs.swift.org/browse/SR-128
    public init(queued parameterValues: [Any??],
                calling onExport: @escaping (AnyEndpoint) -> Void = { _ in },
                onFinished: @escaping (WebServiceModel) -> Void = { _ in }) {
        self.parameterValues = parameterValues
        self.onExport = onExport
        self.onFinished = onFinished
    }

    public required init() {
        self.onExport = { _ in }
        self.onFinished = { _ in }
    }

    open func export<H: Handler>(_ endpoint: Endpoint<H>) {
        onExport(endpoint)

        endpoints.append(EndpointRepresentation(endpoint) { request, parameters, app in
            self.append(injected: parameters)
            let context = endpoint.createConnectionContext(for: self)

            let (response, _) = try context.handleAndReturnParameters(
                request: request,
                eventLoop: app.eventLoopGroup.next(),
                final: true)
                .wait()

            return response.typeErasured
        })
    }

    open func finishedExporting(_ webService: WebServiceModel) {
        onFinished(webService)
    }

    public func append(injected: Any??...) {
        append(injected: injected)
    }

    public func append(injected: [Any??]) {
        parameterValues.append(contentsOf: injected)
    }

    public func request(on index: Int, request: Request, with app: Apodini.Application, parameters: Any??...) -> Response<AnyEncodable> {
        let executable = endpoints[index].evaluateCallback

        do {
            return try executable(request, parameters, app)
        } catch {
            fatalError("Error when handling MockExporter<\(Request.self)> request: \(error)")
        }
    }

    public func requestThrowing(on index: Int, request: Request, with app: Apodini.Application, parameters: Any??...) throws
            -> Response<AnyEncodable> {
        let executable = endpoints[index].evaluateCallback
        return try executable(request, parameters, app)
    }

    public func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Request) throws -> Type?? {
        guard let next = nextParameter(request: request) else {
            return nil // non existence
        }

        guard let value = next else {
            return nil // non existence
        }
        guard let unwrapped = value else {
            return .some(.none) // explicit nil
        }

        guard let casted = unwrapped as? Type else {
            fatalError("MockExporter: Could not cast value \(String(describing: next)) to type \(Type?.self) for '\(parameter.description)'")
        }
        return casted
    }

    private func nextParameter(request: Request) -> Any??? {
        if let emptyRequest = request as? EmptyRequest,
            !emptyRequest.parameters.isEmpty {
            return emptyRequest.parameters.removeFirst()
        } else if !parameterValues.isEmpty {
            return parameterValues.removeFirst()
        }

        return nil
    }
}
#endif
