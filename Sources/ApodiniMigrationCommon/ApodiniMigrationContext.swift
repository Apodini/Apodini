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
    public enum ConfigurationError: Error {
        case inconsistentState
        case notYetCommitted
    }

    /// Holds the `AnyExporterConfiguration`s of currently configured exporters.
    /// As a exporter register your configuration via `register(identifier:for:)`.
    public private(set) var exporterConfigurations: [ApodiniExporterType: AnyExporterConfiguration] = [:]
    private var currentlyConfiguredExporters: Set<ApodiniExporterType> {
        exporterConfigurations
            .keys
            .intoSet()
    }
    /// This property is set via `commitMigratorExporterConfigurations()` and is used to
    /// detect any modifications to `exporterConfiguration`. We rely on this to detect
    /// if there are wrongfully configured exporters (in terms of ordering).
    private var committedExporterConfigurations: Set<ApodiniExporterType>? // swiftlint:disable:this discouraged_optional_collection

    /// Holds any exporter-specific `EndpointIdentifier`s for any handler. Identified by the Apodini `AnyHandlerIdentifier`.
    /// Those are two different types of identifiers.
    /// - `AnyHandlerIdentifier` is Apodini maintained to identify a single `Handler` at runtime
    /// - `EndpointIdentifier` is part of ApodiniMigration and defines any information which identifies an endpoint
    ///   (e.g. operation, path, grpc service name, ...).
    public private(set) var endpointIdentifiers: [AnyHandlerIdentifier: [AnyEndpointIdentifier]] = [:]

    init() {}

    /// This register a new `ExporterConfiguration` for a given `ApodiniExporterType`.
    /// This method MUST be called within the `Configuration/configure(_:)` method!
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

        var identifiers = self.endpointIdentifiers[endpointIdentifier] ?? []
        identifiers.append(AnyEndpointIdentifier(from: identifier))
        self.endpointIdentifiers[endpointIdentifier] = identifiers
    }


    /// This commits the current view of configured exporters.
    /// This MUST be called by the `ApodiniMigration` configuration inside the `Configuration/configure(_:)` method!
    public func commitMigratorExporterConfigurations() {
        self.committedExporterConfigurations = currentlyConfiguredExporters
    }

    /// This method can be used to retrieve the currently set exporter configurations, and checking
    /// if this is consistent with the committed view of the exporter configurations.
    ///
    /// If it is inconsistent, it means that an exporter configured AFTER the calling exporter
    /// has added a exporter configuration. We want to avoid this, as exporters configured AFTER the caller
    /// could add endpoint identifiers which wouldn't be recorded in the `APIDocument`.
    ///
    /// This method MUST be called either in `export` or `finishedExporting` by `ApodiniMigration`.
    ///
    /// - Returns: The exporter configurations indexed by exporter type.
    /// - Throws: Throws an `ConfigurationError` if encountering inconsistent state
    public func retrieveMigratorExporterConfigurations() throws -> [AnyExporterConfiguration] {
        guard let committedExporterConfigurations = committedExporterConfigurations else {
            throw ConfigurationError.notYetCommitted
        }

        guard committedExporterConfigurations == currentlyConfiguredExporters else {
            throw ConfigurationError.inconsistentState
        }

        return exporterConfigurations
            .values
            .intoArray()
    }
}
