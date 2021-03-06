//
//  ExporterConfiguration.swift
//
//
//  Created by Tim Gymnich on 18.1.21.
//

import Foundation
import NIO

/// A `Configuration` for the used `InterfaceExporter`.
public final class ExporterConfiguration: Configuration {
    var semanticModelBuilderBuilder: (SemanticModelBuilder) -> (SemanticModelBuilder) = { $0 }

    /// initalize ExporterConfiguration
    public init() {}

    /// Configure application
    public func configure(_ app: Application) {
        app.exporters.semanticModelBuilderBuilder = semanticModelBuilderBuilder
    }

    /// Adds an `InterfaceExporter`
    public func exporter<T: InterfaceExporter>(_ exporter: T.Type) -> Self {
        let builder = semanticModelBuilderBuilder
        semanticModelBuilderBuilder = { model in
            builder(model).with(exporter: exporter)
        }
        return self
    }

    /// Adds an `InterfaceExporter`
    public func exporter<T: StaticInterfaceExporter>(_ exporter: T.Type) -> Self {
        let builder = semanticModelBuilderBuilder
        semanticModelBuilderBuilder = { model in
            builder(model).with(exporter: exporter)
        }
        return self
    }
}
