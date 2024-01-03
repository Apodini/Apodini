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

final class ParameterCountTests: ApodiniTests {
    func testOneParameterPass() throws {
        try assertNoFinding(handler: OneParameterHandler(), bestPractice: ReasonableParameterCount())
    }
    
    func testElevenParameterFail() throws {
        try assertOneFinding(
            handler: ElevenParameterHandler(),
            bestPractice: ReasonableParameterCount(),
            expectedFinding: ParameterCountFinding.tooManyParameters(count: 11)
        )
    }
    
    func testElevenParameterPass() throws {
        try assertNoFinding(
            handler: ElevenParameterHandler(),
            bestPractice: ParameterCountConfiguration(maximumCount: 11).configure()
        )
    }
}

struct OneParameterHandler: Handler {
    @Parameter var param1: Int
    
    func handle() -> String { "" }
}

struct ElevenParameterHandler: Handler {
    @Parameter var param1: Int
    @Parameter var param2: Int
    @Parameter var param3: Int
    @Parameter var param4: Int
    @Parameter var param5: Int
    @Parameter var param6: Int
    @Parameter var param7: Int
    @Parameter var param8: Int
    @Parameter var param9: Int
    @Parameter var param10: Int
    @Parameter var param11: Int
    
    func handle() -> String { "" }
}

func setHandlerAndGetAudit<H: Handler>(_ handler: H, bestPractice: any BestPractice) throws -> Audit {
    let webService = ParameterWebService(handler: handler)
    let app = Application()
    let endpoint = try getEndpointFromWebService(webService, app, "TheHandler")
    return bestPractice.check(for: endpoint, app)
}

func assertNoFinding<H: Handler>(
    handler: H,
    bestPractice: any BestPractice
) throws {
    let audit = try setHandlerAndGetAudit(handler, bestPractice: bestPractice)
    XCTAssertEqual(audit.findings.count, 0)
}

func assertOneFinding<F: Finding & Equatable, H: Handler>(
    handler: H,
    bestPractice: any BestPractice,
    expectedFinding: F
) throws {
    let audit = try setHandlerAndGetAudit(handler, bestPractice: bestPractice)
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

struct ParameterWebService<H: Handler>: WebService {
    let handler: H
    
    var content: some Component {
        handler.endpointName("TheHandler")
    }
}

extension ParameterWebService {
    init() {
        self.handler = OneParameterHandler() as! H
    }
}

extension ParameterWebService: Decodable {
    init(from: any Decoder) {
        self.handler = OneParameterHandler() as! H
    }
}
