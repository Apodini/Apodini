//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import Apodini
@testable import ApodiniAudit
@testable import ApodiniREST
import ApodiniExtension

struct BestPracticeWebService: WebService {
    var pluralString = "images"
    
    @PathParameter var someId: UUID
    
    var content: some Component {
        Group(pluralString, $someId) {
            EmptyGetHandler(someId: $someId).endpointName("GetStoreHandler")
        }
    }
}

struct EmptyGetHandler: Handler {
    @Binding var someId: UUID
    
    func handle() -> String {
        "Hi"
    }
}

func getEndpointFromWebService(_ webService: BestPracticeWebService, _ app: Application, _ ename: String) throws -> AnyEndpoint {
    let modelBuilder = SemanticModelBuilder(app)
    let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
    webService.accept(visitor)
    visitor.finishParsing()
    let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first {
        guard let name = $0[Context.self].get(valueFor: EndpointNameMetadata.Key.self),
            case .name(let name, _) = name else {
            return false
        }
        return name == ename
    })
    return endpoint
}

func generateAudit(for bestPractice: BestPractice, _ endpoint: AnyEndpoint, _ app: Application) {
    }
