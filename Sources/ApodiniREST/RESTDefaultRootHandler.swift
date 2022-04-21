//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniNetworking

/// A RoutesHandler which is automatically registered to the root path
/// if there is no Endpoint registered under the root, in order to serve entry point links.
struct RESTDefaultRootHandler {
    let app: Apodini.Application
    let exporterConfiguration: REST.ExporterConfiguration
    let relationships: Set<RelationshipDestination>
    
    /// Registers a GET handler on root path
    func register(on app: Apodini.Application, rootPath: EndpointPath?) {
        try! app.httpServer.registerRoute(.GET, []) { request in
            ResponseContainer(
                Empty.self,
                links: relationships.formatRelationships(
                    into: [:],
                    with: LinksFormatter(configuration: app.httpConfiguration, rootPath: rootPath)
                ),
                encoder: exporterConfiguration.encoder
            ).encodeResponse(for: request)
        }
    }
}
