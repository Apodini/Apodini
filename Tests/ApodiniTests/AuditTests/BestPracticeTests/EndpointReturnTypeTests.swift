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

final class EndpointReturnTypeTests: ApodiniTests {
    func testResponseTypeBestPractice() throws {
        try assertOneFinding(
            bestPractice: EndpointHasComplexReturnType(),
            handlerName: "AHandler",
            expectedFinding: ReturnTypeFinding.hasPrimitiveReturnType(.update)
        )
        
        try assertOneFinding(
            bestPractice: EndpointHasComplexReturnType(),
            handlerName: "BHandler",
            expectedFinding: ReturnTypeFinding.hasPrimitiveReturnType(.delete)
        )
        
        try assertNoFinding(
            bestPractice: EndpointHasComplexReturnType(),
            handlerName: "CHandler"
        )
        
        try assertNoFinding(
            bestPractice: EndpointHasComplexReturnType(),
            handlerName: "DHandler"
        )
    }
}

struct ReturnTypeWebService: WebService {
    var content: some Component {
        Group("a") {
            LetterAHandler().endpointName("AHandler")
        }
        Group("b") {
            BHandler().endpointName("BHandler")
        }
        Group("c") {
            CHandler().endpointName("CHandler")
        }
        Group("d") {
            CHandler().endpointName("DHandler")
        }
    }
}

struct LetterAHandler: Handler {
    func handle() -> Apodini.Status {
        .ok
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.update)
    }
}

struct BHandler: Handler {
    func handle() -> EventLoopFuture<Apodini.Status> {
        fatalError("Can't build an eventloop here")
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.delete)
    }
}

struct CHandler: Handler {
    func handle() -> Apodini.Status {
        .noContent
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.create)
    }
}

struct DHandler: Handler {
    func handle() -> Response<String> {
        .final("")
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.read)
    }
}

func getAudit(
    bestPractice: BestPractice,
    handlerName: String
) throws -> Audit {
    let webService = ReturnTypeWebService()
    let app = Application()
    let endpoint = try getEndpointFromWebService(webService, app, handlerName)
    return bestPractice.check(for: endpoint, app)
}

func assertNoFinding(
    bestPractice: BestPractice,
    handlerName: String
) throws {
    let audit = try getAudit(bestPractice: bestPractice, handlerName: handlerName)
    XCTAssertEqual(audit.findings.count, 0)
}

func assertOneFinding<F: Finding & Equatable>(
    bestPractice: BestPractice,
    handlerName: String,
    expectedFinding: F
) throws {
    let audit = try getAudit(bestPractice: bestPractice, handlerName: handlerName)
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
