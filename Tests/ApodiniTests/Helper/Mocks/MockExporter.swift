//
// Created by Andreas Bauer on 25.12.20.
//

import Foundation
import class Vapor.Application
import class Vapor.Request
@testable import Apodini

extension String: ExporterRequest {}

class MockExporter<Request: ExporterRequest>: InterfaceExporter {
    var parameterValues: [Any??] = []

    /// Creates a new MockExporter which uses the passed parameter values as FIFO queue on retrieveParameter
    required init(queued parameterValues: Any??...) {
        self.parameterValues = parameterValues
    }

    // See https://bugs.swift.org/browse/SR-128
    required init(queued parameterValues: [Any??]) {
        self.parameterValues = parameterValues
    }

    required init(_ app: Apodini.Application) {}

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        // do nothing
    }

    func finishedExporting(_ webService: WebServiceModel) {
        // do nothing
    }

    func append(injected: Any??...) {
        append(injected: injected)
    }

    func append(injected: [Any??]) {
        parameterValues.append(contentsOf: injected)
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Request) throws -> Type?? {
        guard let first = parameterValues.first else {
            print("WARN: MockExporter failed to retrieve next parameter for '\(parameter.description)'. Queue is empty")
            return nil // non existence
        }
        parameterValues.removeFirst()

        guard let value = first else {
            return nil // non existence
        }
        guard let unwrapped = value else {
            return .null // explicit nil
        }

        guard let casted = unwrapped as? Type else {
            fatalError("MockExporter: Could not cast value \(String(describing: first)) to type \(Type?.self) for '\(parameter.description)'")
        }
        return casted
    }
}
