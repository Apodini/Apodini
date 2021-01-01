//
// Created by Andi on 29.12.20.
//
import NIO
import Foundation
import protocol FluentKit.Database

protocol Request: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns a description of the Request.
    /// If the `ExporterRequest` also conforms to `CustomStringConvertible`, its `description`
    /// will be appended.
    var description: String { get }
    /// Returns a debug description of the Request.
    /// If the `ExporterRequest` also conforms to `CustomDebugStringConvertible`, its `debugDescription`
    /// will be appended.
    var debugDescription: String { get }

    var endpoint: AnyEndpoint { get }

    var eventLoop: EventLoop { get }

    var database: (() -> Database)? { get }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element
}

struct ValidatedRequest<I: InterfaceExporter, H: Handler>: Request {
    var description: String {
        var description = "Validated Request:\n"
        if let convertible = exporterRequest as? CustomStringConvertible {
            description += convertible.description
        }
        return description
    }
    var debugDescription: String {
        var debugDescription = "Validated Request:\n"
        if let convertible = exporterRequest as? CustomDebugStringConvertible {
            debugDescription += convertible.debugDescription
        }
        return debugDescription
    }

    var exporter: I
    var exporterRequest: I.ExporterRequest
    
    let validatedParameterValues: [UUID: Any]

    let storedEndpoint: Endpoint<H>
    var endpoint: AnyEndpoint {
        storedEndpoint
    }

    var eventLoop: EventLoop

    var database: (() -> Database)?

    init(
        for exporter: I,
        with request: I.ExporterRequest,
        using validatedParameterValues: [UUID: Any],
        on endpoint: Endpoint<H>,
        running eventLoop: EventLoop,
        database: (() -> Database)? = nil
    ) {
        self.exporter = exporter
        self.exporterRequest = request
        self.validatedParameterValues = validatedParameterValues
        self.storedEndpoint = endpoint
        self.eventLoop = eventLoop
        self.database = database
    }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        validatedParameterValues[parameter.id] as! Element
    }
}

// TODO: deleta everything below
struct ApodiniRequest<I: InterfaceExporter, H: Handler>: Request {
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

    let storedEndpoint: Endpoint<H>
    var endpoint: AnyEndpoint {
        storedEndpoint
    }

    var eventLoop: EventLoop

    var database: (() -> Database)?

    init(
        for exporter: I,
        with request: I.ExporterRequest,
        on endpoint: Endpoint<H>,
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
        let untypedResult: Any?? = try exporter.retrieveParameter(parameter, for: request)
        
        // MARK: Check Type
        
        guard let result = untypedResult as? Type?? else {
            throw InputValidationError.some("Did receive input of wrong type for parameter '\(parameter.description)'.")
        }
        
        // MARK: Check Nullability and Necessity

        var retrievedValue: Type?
        if result == nil {
            // Result is nil, meaning retrieveParameter returned nil, meaning
            // the exporter encoded that there was no value provided for this parameter.
            // => NON EXISTENCE

            switch parameter.necessity {
            case .required:
                throw InputValidationError.some("Didn't retrieve any parameters for a required '\(parameter.description)'.")
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
        
        var returnValue: Element
        if let wrappedRetrievedValue = retrievedValue {
            // Reaching here we know, that Element=Type, thus we can cast as below
            // swiftlint:disable:next force_cast
            returnValue = wrappedRetrievedValue as! Element
        } else if parameter.nilIsValidValue {
            // as nilIsValidValue=true, we know that Element=Optional<Type>, thus we can cast as below.
            // swiftlint:disable:next force_cast
            returnValue = retrievedValue as! Element
        } else {
            throw InputValidationError.some("Parameter retrieval returned explicit nil, though explicit nil is not valid for the '\(parameter.description)'")
        }
        
        // MARK: Check Mutability
        
//        switch parameter.options.option(for: .mutability) ?? .variable {
//        case .constant:
//            if let initialValue = parameter.initialValue {
//                if !unsafeEqual(a: initialValue, b: retrievedValue) {
//                    #warning("Create proper Apodini defined error.")
//                    throw InputValidationError.some("Parameter retrieval returned value for constant '\(parameter.description)' even though its value has already been defined.")
//                }
//            } else {
//                parameter.initialValue = retrievedValue
//            }
//        case .variable:
//            break
//        }

        return returnValue
    }
}
