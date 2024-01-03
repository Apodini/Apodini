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
    var segment = ""
    
    @PathParameter var someId: UUID
    
    var content: some Component {
        Group(segment, $someId) {
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

func getEndpointFromWebService<W: WebService>(_ webService: W, _ app: Application, _ ename: String) throws -> any AnyEndpoint {
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

func setSegmentAndGetAudit(
    segment: String,
    bestPractice: any BestPractice
) throws -> Audit {
    var webService = BestPracticeWebService()
    webService.segment = segment
    let app = Application()
    let endpoint = try getEndpointFromWebService(webService, app, "GetStoreHandler")
    return bestPractice.check(for: endpoint, app)
}

func assertNoFinding(
    segment: String,
    bestPractice: any BestPractice
) throws {
    let audit = try setSegmentAndGetAudit(segment: segment, bestPractice: bestPractice)
    XCTAssertEqual(audit.findings.count, 0)
}

func assertOneFinding<F: Finding & Equatable>(
    segment: String,
    bestPractice: any BestPractice,
    expectedFinding: F
) throws {
    let audit = try setSegmentAndGetAudit(segment: segment, bestPractice: bestPractice)
    XCTAssertEqual(audit.findings.count, 1)
    guard let finding = audit.findings[0] as? F else {
        XCTFail("Could not typecast Finding")
        return
    }
    guard finding == expectedFinding else {
        XCTFail("Findings \(finding) and \(expectedFinding) are not equal!")
        return
    }
}
