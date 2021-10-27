//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Vapor

/// A RoutesHandler which is automatically registered to the root path
/// if there is no Endpoint registered under the root, in order to server entry point links.
struct RESTDefaultRootHandler {
    let app: Apodini.Application
    let exporterConfiguration: REST.ExporterConfiguration
    let relationships: Set<RelationshipDestination>

    // Registers a GET handler on root path
    func register(on app: Vapor.Application) {
        app.get(use: self.handleRequest)
    }

    func handleRequest(_: Vapor.Request) -> ResponseContainer {
        ResponseContainer(
            Empty.self,
            links: relationships.formatRelationships(into: [:], with: LinksFormatter(configuration: app.httpConfiguration)),
            encoder: exporterConfiguration.encoder
        )
    }
}
