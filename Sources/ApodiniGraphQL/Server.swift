//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini


class GraphQLServer {
    let schemaBuilder: GraphQLSchemaBuilder
    
    init() {
        schemaBuilder = GraphQLSchemaBuilder()
    }
    
//    func register<H: Handler>(endpoint: Endpoint<H>) throws {
//        try schemaBuilder.add(endpoint)
//    }
}
