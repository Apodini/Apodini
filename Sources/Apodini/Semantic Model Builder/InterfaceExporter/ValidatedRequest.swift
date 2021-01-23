//
// Created by Andi on 29.12.20.
//
import NIO
import Foundation
import protocol FluentKit.Database

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
        guard let value = validatedParameterValues[parameter.id] as? Element else {
            fatalError("ValidatedRequest could not retrieve parameter '\(parameter.id)' after validation.")
        }
        return value
    }
}
