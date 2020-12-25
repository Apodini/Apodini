//
// Created by Andi on 25.12.20.
//

import Foundation
import class Vapor.Application
import class Vapor.Request
@testable import Apodini

extension String: ExporterRequest {}
extension Vapor.Request: ExporterRequest, WithEventLoop {}

class MockExporter<Request: ExporterRequest>: InterfaceExporter {
    var parameterValues: [Any?] = []

    /// Creates a new MockExporter which uses the passed parameter values as FIFO queue on retrieveParameter
    required init(queued parameterValues: Any?...) {
        self.parameterValues = parameterValues
    }

    // See https://bugs.swift.org/browse/SR-128
    required init(queued parameterValues: [Any?]) {
        self.parameterValues = parameterValues
    }

    required init(_ app: Application) {}

    func export<C: Component>(_ endpoint: Endpoint<C>) {
        // do nothing
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Request) throws -> Type? {
        let first = parameterValues.first
        if first == nil {
            fatalError("MockExporter failed to retrieve next parameter for '\(parameter.name)'. Queue is empty")
        }
        parameterValues.removeFirst()

        guard let unwrapped = first else {
            return nil
        }

        guard let casted = unwrapped as? Type? else {
            fatalError("MockExporter: Could not cast parameter '\(parameter.name)' value \(String(describing: first)) to type \(Type?.self)")
        }


        return casted
    }
}
