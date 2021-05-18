//
// Created by Andreas Bauer on 29.12.20.
//
import NIO
import Foundation

struct ValidatedRequest<I: InterfaceExporter, H: Handler>: Request {
    var description: String {
        var request = "Validated Request:\n"
        if let convertible = exporterRequest as? CustomStringConvertible {
            request += convertible.description
        }
        return request
    }
    var debugDescription: String {
        var request = "Validated Request:\n"
        if let convertible = exporterRequest as? CustomDebugStringConvertible {
            request += convertible.debugDescription
        }
        return request
    }

    var endpoint: AnyEndpoint {
        storedEndpoint
    }

    let exporter: I
    let exporterRequest: I.ExporterRequest
    let validatedParameterValues: [UUID: Any]
    let storedEndpoint: Endpoint<H>
    let eventLoop: EventLoop
    let remoteAddress: SocketAddress?

    init(
        for exporter: I,
        with request: I.ExporterRequest,
        using validatedParameterValues: [UUID: Any],
        on endpoint: Endpoint<H>,
        running eventLoop: EventLoop,
        remoteAddress: SocketAddress?
    ) {
        self.exporter = exporter
        self.exporterRequest = request
        self.validatedParameterValues = validatedParameterValues
        self.storedEndpoint = endpoint
        self.eventLoop = eventLoop
        self.remoteAddress = remoteAddress
    }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        guard let value = validatedParameterValues[parameter.id] as? Element else {
            fatalError("ValidatedRequest could not retrieve parameter '\(parameter.id)' after validation.")
        }
        return value
    }
}


struct ValidatingRequest<I: InterfaceExporter, H: Handler>: Request {
    var description: String {
        var request = "Validating Request:\n"
        if let convertible = exporterRequest as? CustomStringConvertible {
            request += convertible.description
        }
        return request
    }
    var debugDescription: String {
        var request = "Validating Request:\n"
        if let convertible = exporterRequest as? CustomDebugStringConvertible {
            request += convertible.debugDescription
        }
        return request
    }

    var endpoint: AnyEndpoint {
        storedEndpoint
    }

    let exporter: I
    let exporterRequest: I.ExporterRequest
    let endpointValidator: EndpointValidator<I, H>
    let storedEndpoint: Endpoint<H>
    let eventLoop: EventLoop
    let remoteAddress: SocketAddress?

    init(
        for exporter: I,
        with request: I.ExporterRequest,
        using endpointValidator: EndpointValidator<I, H>,
        on endpoint: Endpoint<H>,
        running eventLoop: EventLoop,
        remoteAddress: SocketAddress?
    ) {
        self.exporter = exporter
        self.exporterRequest = request
        self.endpointValidator = endpointValidator
        self.storedEndpoint = endpoint
        self.eventLoop = eventLoop
        self.remoteAddress = remoteAddress
    }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        try endpointValidator.validate(one: parameter.id)
    }
    
    func retrieveAnyParameter(_ id: UUID) throws -> Any {
        try endpointValidator.validate(one: id)
    }
}
