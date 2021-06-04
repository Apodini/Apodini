//
// Created by Andreas Bauer on 25.12.20.
//

import Foundation
import class Vapor.Application
import class Vapor.Request
import Apodini

extension String: ExporterRequest {}

open class MockExporter<Request: ExporterRequest>: InterfaceExporter {
    var parameterValues: [Any??] = []
    
    let onExport: (AnyEndpoint) -> Void
    let onFinished: (WebServiceModel) -> Void

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

    public required init(_ app: Apodini.Application) {
        self.onExport = { _ in }
        self.onFinished = { _ in }
    }

    open func export<H: Handler>(_ endpoint: Endpoint<H>) {
        onExport(endpoint)
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

    public func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Request) throws -> Type?? {
        guard let first = parameterValues.first else {
            print("WARN: MockExporter failed to retrieve next parameter for '\(parameter.description)'. Queue is empty")
            return nil // non existence
        }
        parameterValues.removeFirst()

        guard let value = first else {
            return nil // non existence
        }
        guard let unwrapped = value else {
            return .some(.none) // explicit nil
        }

        guard let casted = unwrapped as? Type else {
            fatalError("MockExporter: Could not cast value \(String(describing: first)) to type \(Type?.self) for '\(parameter.description)'")
        }
        return casted
    }
}
