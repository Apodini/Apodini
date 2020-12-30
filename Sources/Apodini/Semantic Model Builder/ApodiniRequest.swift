//
// Created by Andi on 29.12.20.
//
import NIO
import protocol FluentKit.Database

struct ApodiniRequest<I: InterfaceExporter, C: Component>: Request {
    var description: String {
        var description = "Apodini Request:\n"
        if let convertible = exporterRequest as? CustomStringConvertible {
            description += convertible.description
        }
        return description
    }
    var debugDescription: String {
        var debugDescription = "Apodini Request:\n"
        if let convertible = exporterRequest as? CustomDebugStringConvertible {
            debugDescription += convertible.debugDescription
        }
        return debugDescription
    }

    var exporter: I
    var exporterRequest: I.ExporterRequest

    var storedEndpoint: Endpoint<C>
    var endpoint: AnyEndpoint {
        storedEndpoint
    }

    var eventLoop: EventLoop

    var database: (() -> Database)?

    init(
            for exporter: I,
            with request: I.ExporterRequest,
            on endpoint: Endpoint<C>,
            running eventLoop: EventLoop,
            database: (() -> Database)? = nil
    ) {
        self.exporter = exporter
        self.exporterRequest = request
        self.storedEndpoint = endpoint
        self.eventLoop = eventLoop
        self.database = database
    }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        guard let endpointParameter = endpoint.findParameter(for: parameter.id) else {
            fatalError("Could not find the associated Parameter model for \(parameter.id) with type \(Element.self). Something has gone horribly wrong!")
        }

        let retrieval = ParameterRetrievalDelegation<Element, I>(exporter: exporter, request: exporterRequest)
        return try endpointParameter.accept(retrieval)
    }
}

/// This visitor is used to do the actual call to `InterfaceExporter.retrieveParameter(...)`.
/// It also handles all checks done for a Parameter, meaning checking that a value is present for a required parameter
/// and for optional parameters setting a optionally supplied default value.
///
/// Those four main cases are handled:
/// ```@Parameter var value: String``` required, no default value, "explicit nil" not valid
/// ```@Parameter var value: String?``` optional, no default value, "explicit nil" is valid, nilIsValidValue=true
/// ```@Parameter var value: String = "ASdf"``` optional, with default value, "explicit nil" not valid
/// ```@Parameter var value: String? = "ASdf"``` optional, with default value, "explicit nil" is valid, nilIsValidValue=true
private struct ParameterRetrievalDelegation<Element: Codable, I: InterfaceExporter>: EndpointParameterThrowingVisitor {
    var exporter: I
    var request: I.ExporterRequest

    func visit<Type: Codable>(parameter: EndpointParameter<Type>) throws -> Element {
        let result: Type?? = try exporter.retrieveParameter(parameter, for: request)

        var retrievedValue: Type?
        if result == nil {
            // Result is nil, meaning retrieveParameter returned nil, meaning
            // the exporter encoded that there was no value provided for this parameter.
            // => NON EXISTENCE

            switch parameter.necessity {
            case .required:
                #warning("Create some Apodini defined error, which is returned to the exporter so it can encode a response.")
                fatalError("Didn't retrieve any parameters for a required '\(parameter.description)'.")
            case .optional:
                // Writing the defaultValue into retrievedValue
                // Either the optional parameter stays nil if the does not exists any default value
                // or obviously the default value is used when it exists
                retrievedValue = parameter.defaultValue
            }
        } else {
            // swiftlint:disable:next force_unwrapping
            retrievedValue = result!
        }

        guard let wrappedRetrievedValue = retrievedValue else {
            if !parameter.nilIsValidValue {
                #warning("Create some Apodini defined error, which is returned to the exporter so it can encode a response.")
                fatalError("Parameter retrieval returned explicit nil, though explicit nil is not valid for the '\(parameter.description)'")
            }

            // as nilIsValidValue=true, we know that Element=Optional<Type>, thus we can cast as below.
            // swiftlint:disable:next force_cast
            return retrievedValue as! Element
        }

        // Reaching here we know, that Element=Type, thus we can cast as below
        // swiftlint:disable:next force_cast
        return wrappedRetrievedValue as! Element
    }
}
