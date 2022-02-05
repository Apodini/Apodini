//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// This context, accessible via `Application/apodiniMigration` is used to exchange
/// information between ApodiniMigration supporting exporters and the `ApodiniMigrationInterfaceExporter`.
public class ApodiniMigrationContext {
    /// Holds the `AnyExporterConfiguration`s of currently configured exporters.
    /// As a exporter register your configuration via `register(identifier:for:)`.
    private var exporterConfigurations: [ApodiniExporterType: AnyExporterConfiguration] = [:]
    /// Retrieves the currently configured `AnyExporterConfiguration`s.
    public var configuredExporters: [AnyExporterConfiguration] {
        exporterConfigurations
            .values
            .intoArray()
    }
    private var currentlyConfiguredExporters: Set<ApodiniExporterType> {
        exporterConfigurations
            .keys
            .intoSet()
    }

    /// Holds any exporter-specific `EndpointIdentifier`s for any handler. Identified by the Apodini `AnyHandlerIdentifier`.
    /// Those are two different types of identifiers.
    /// - `AnyHandlerIdentifier` is Apodini maintained to identify a single `Handler` at runtime
    /// - `EndpointIdentifier` is part of ApodiniMigration and defines any information which identifies an endpoint
    ///   (e.g. operation, path, grpc service name, ...).
    public private(set) var endpointIdentifiers: [AnyHandlerIdentifier: [AnyElementIdentifier]] = [:]

    // TODO docs!
    public private(set) var typeInformationIdentifiers: [SwiftTypeIdentifier: TypeInformationAddendum] = [:]

    init() {}

    /// This register a new `ExporterConfiguration` for a given `ApodiniExporterType`.
    /// This method SHOULD be called within the `Configuration/configure(_:)` method!
    ///
    /// - Parameters:
    ///   - configuration: The exporter configuration.
    ///   - type: The exporter type.
    public func register<Configuration: ExporterConfiguration>(configuration: Configuration, for type: ApodiniExporterType) {
        self.exporterConfigurations[type] = AnyExporterConfiguration(configuration)
    }

    /// This method records a `EndpointIdentifier` for a given `Endpoint`.
    /// The provided information is added to the `APIDocument` and is considered in the `MigrationGuide`.
    /// - Parameters:
    ///   - identifier: The `EndpointIdentifier` which is to be added.
    ///   - endpoint: The given Apodini `Endpoint`.
    public func register<H: Handler, Identifier: EndpointIdentifier>(
        identifier: Identifier,
        for endpoint: Endpoint<H>
    ) {
        let endpointIdentifier = endpoint[AnyHandlerIdentifier.self]

        self.endpointIdentifiers[endpointIdentifier, default: []]
            .append(AnyElementIdentifier(from: identifier))
    }

    public func register<Identifier: TypeInformationIdentifier>(identifier: Identifier, for type: SwiftTypeIdentifier, children: String? = nil) {
        if let children = children {
            self.typeInformationIdentifiers[type, default: TypeInformationAddendum()]
                .childrenIdentifiers[children, default: []]
                .append(AnyElementIdentifier(from: identifier))
        } else {
            self.typeInformationIdentifiers[type, default: TypeInformationAddendum()]
                .identifiers
                .append(AnyElementIdentifier(from: identifier))
        }
    }

    public func retrieveTypeInformationAddendum(for name: SwiftTypeIdentifier) -> TypeInformationAddendum? {
        guard let addendum = typeInformationIdentifiers[name]?.markingQueried() else {
            return nil
        }

        return addendum
    }
}
