//
//  ExporterConfiguration.swift
//
//
//  Created by Tim Gymnich on 18.1.21.
//

import Foundation
import NIO

/// A `Configuration` for HTTP.
/// The configuration can be done in two ways, either via the
/// command line arguments --hostname, --port and --bind or via the
/// function `address`
public class ExporterConfiguration: Configuration {

    var semanticModelBuilderBuilder: (SemanticModelBuilder) -> (SemanticModelBuilder) = id

    /// initalize HTTPConfiguration
    public init() {}

    /// Configure application
    public func configure(_ app: Application) {
        app.exporters.semanticModelBuilderBuilder = semanticModelBuilderBuilder
    }

    /// Sets the http server address
    public func exporter<T: InterfaceExporter>(_ exporter: T.Type) -> Self {
        let builder = semanticModelBuilderBuilder
        semanticModelBuilderBuilder = { model in
            return builder(model).with(exporter: exporter)
        }
        return self
    }

    public func exporter<T: StaticInterfaceExporter>(_ exporter: T.Type) -> Self {
        let builder = semanticModelBuilderBuilder
        semanticModelBuilderBuilder = { model in
            return builder(model).with(exporter: exporter)
        }
        return self
    }
}

func id<T>(_ arg: T) -> T { arg }
