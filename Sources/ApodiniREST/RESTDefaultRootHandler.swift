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
    let configuration: REST.Configuration
    let exporterConfiguration: REST.ExporterConfiguration
    let relationships: Set<RelationshipDestination>
    
    // Registers a GET handler on root path
    func register(on app: Apodini.Application) {
        //app.get(use: self.handleRequest)
        //app.lkHttpServer.registerRoute(.GET, [], handler: self.handleRequest)
        //app.lkHttpServer.registerRoute(.GET, route: [], handler: self.handleRequest)
        app.lkHttpServer.registerRoute(.GET, []) { request in
            ResponseContainer(
                Empty.self,
                links: relationships.formatRelationships(into: [:], with: LinksFormatter(configuration: configuration)),
                encoder: exporterConfiguration.encoder
            ).encodeResponse(for: request)
        }
    }

//    func handleRequest(_: LKHTTPRequest) -> ResponseContainer {
//        ResponseContainer(
//            Empty.self,
//            links: relationships.formatRelationships(into: [:], with: LinksFormatter(configuration: configuration)),
//            encoder: exporterConfiguration.encoder
//        )
//    }
    
//    // TODO this used to be implenenbted in a way that it'd
//    func handleRequest(request: LKHTTPRequest) -> ResponseContainer {
//        ResponseContainer(
//            Empty.self,
//            links: relationships.formatRelationships(into: [:], with: LinksFormatter(configuration: configuration)),
//            encoder: exporterConfiguration.encoder
//        ).encodeResponse(for: <#T##LKHTTPRequest#>)
//    }
}
