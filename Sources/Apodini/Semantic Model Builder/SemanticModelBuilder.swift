//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO


class SemanticModelBuilder: InterfaceExporterVisitor {
    private(set) var app: Application

    /// This property (which is to be made configurable) toggles if the default `ParameterNamespace`
    /// (which is the strictest option possible) can be overridden by Exporters, which may allow more lenient
    /// restrictions. In the end the Exporter with the strictest `ParameterNamespace` will dictate the requirements
    /// towards parameter naming.
    private let allowLenientParameterNamespaces = true
    
    private(set) var collectedEndpoints: [_AnyEndpoint] = []

    init(_ app: Application) {
        self.app = app
    }

    func register<H: Handler>(handler: H, withContext context: Context) {
        let handler = handler.inject(app: app)
        
        // GlobalSharedRepository's content lives on the app's `Store`, this is only a wrapper for accessing it
        let globalSharedRepository = GlobalSharedRepository<LazyHashmapSharedRepository>(app)
        
        let localSharedRepository = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: handler, context)
        
        // We first only build the sharedRepositorys and the `Endpoint`. The validation and exporting is done at the
        // beginning of `finishedRegistration`. This way `.global` `KnowledgeSource`s get a complete view of
        // the web service even when accessed from an `Endpoint`.
        collectedEndpoints.append(Endpoint<H>(sharedRepository: localSharedRepository))
    }

    func finishedRegistration() {
        if app.interfaceExporters.isEmpty {
            app.logger.warning("There aren't any Interface Exporters registered!")
        }
        app.interfaceExporters.acceptAll(self)
    }

    func visit<I>(exporter: I) where I: InterfaceExporter {
        call(exporter: exporter)
        exporter.finishedExporting(WebServiceModel(sharedRepository: GlobalSharedRepository<LazyHashmapSharedRepository>(app)))
    }

    private func call<I: InterfaceExporter>(exporter: I) {
        let endpoints: [_AnyEndpoint]
        do {
            endpoints = try app.lifecycle.handlers.reduce(self.collectedEndpoints) { endpoints, lifecycleHandler in
                try endpoints.flatMap { try lifecycleHandler.map(endpoint: $0, app: self.app, for: exporter) as! [_AnyEndpoint] }
            }
        } catch {
            fatalError("Error during lifecycle-endpoint-filtering: \(error)")
        }
        for endpoint in endpoints {
            // before we run unnecessary export steps, we first verify that the Endpoint is indeed valid
            // in the case of not allowing lenient namespace definitions we just pass a empty array
            // which will result in the default namespace being used
            endpoint.parameterNameCollisionCheck(in: allowLenientParameterNamespaces ? I.parameterNamespace : .global)
            endpoint.exportEndpoint(on: exporter)
        }
    }
}


extension Handler {
    /// If `self` is an `IdentifiableHandler`, returns the handler's `handlerId`. Otherwise nil
    internal func getExplicitlySpecifiedIdentifier() -> AnyHandlerIdentifier? {
        // Intentionally using the if-let here to make sure we get an error
        // if for some reason the ATRVisitor's return type isn't an optional anymore,
        // since that (a guaranteed non-nil return value) would defeat the whole point of this function
        if let identifiableHandler = self as? any IdentifiableHandler {
            return identifiableHandler.handlerId
        } else {
            return nil
        }
    }
}
