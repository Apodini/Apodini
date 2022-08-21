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
@testable import ApodiniHTTP
import PythonKit


final class ConfigurationTests: ApodiniTests {
    struct SomeHandler: Handler {
        func handle() -> Response<String> {
            .final(information: ETag("aosidhaoshid"))
        }

        var metadata: AnyHandlerMetadata {
            SelectBestPractices(.include, .urlPath)
        }
    }

    class CustomBP: BestPractice {
        func check(into audit: Audit, _ app: Application) {
            audit.recordFinding(CustomFinding.finding)
        }

        required init() { }

        static var scope: BestPracticeScopes = .all
        static var category: BestPracticeCategories = .httpMethod
    }

    enum CustomFinding: Finding, Equatable {
        var diagnosis: String {
            ""
        }

        case finding
    }
    
    struct AuditWebService: WebService {
        var addCustomConfig = true
        
        var content: some Component {
            Group("hi") {
                SomeHandler()
            }
        }

        @ConfigurationBuilder var conf: Configuration {
            HTTP {
                APIAuditor {
                    if addCustomConfig {
                        EmptyBestPracticeConfiguration<CustomBP>()
                    }
                }
            }
        }
        
        var configuration: Configuration {
            conf
        }
    }
    
    struct AuditWebService2: WebService {
        var content: some Component {
            Group("hi") {
                SomeHandler()
            }
        }

        @ConfigurationBuilder var conf: Configuration {
            REST {
                APIAuditor()
            }
        }
        
        var configuration: Configuration {
            conf
        }
    }
    
    func testConfigurationBuilder() throws {
        let withoutWebService = AuditWebService(addCustomConfig: false)
        try assertNoFinding(
            webService: withoutWebService,
            bestPracticeType: CustomBP.self,
            endpointPath: "/hi"
        )
        
        let withWebService = AuditWebService(addCustomConfig: true)
        try assertOneFinding(
            webService: withWebService,
            bestPracticeType: CustomBP.self,
            endpointPath: "/hi",
            expectedFinding: CustomFinding.finding
        )
    }
    
    func testOnlyHTTPBPs() throws {
        // Test that Best Practices with scope .rest are only run for API's with a REST configuration.
        let httpWebService = AuditWebService()
        try assertNoFinding(
            webService: httpWebService,
            bestPracticeType: URLPathSegmentLength.self,
            endpointPath: "/hi"
        )
        
        let restWebService = AuditWebService2()
        try assertOneFinding(
            webService: restWebService,
            bestPracticeType: URLPathSegmentLength.self,
            endpointPath: "/hi",
            expectedFinding: URLPathSegmentLengthFinding.segmentTooShort(segment: "hi")
        )
    }
    
    struct MultipleAuditorsWebService: WebService {
        var content: some Component {
            SomeHandler()
        }

        var configuration: Configuration {
            REST {
                APIAuditor()
            }
            HTTP(rootPath: "http") {
                APIAuditor()
            }
        }
    }
    
    func testRegisterCommandOnce() throws {
        // Test that the AuditCommand is only registered once, even if there are multiple Auditors configured
        let webService = MultipleAuditorsWebService()
        
        let app = Application()
        try MultipleAuditorsWebService.start(mode: .boot, app: app, webService: webService)
        let commands = webService.configuration._commands
        
        // Filter to get only auditcommands
        let auditCommands = commands.filter { cmd in
            cmd is AuditCommand<MultipleAuditorsWebService>.Type
        }
        
        XCTAssertEqual(auditCommands.count, 1)
        app.shutdown()
    }
}

func getAudit<W: WebService>(
    webService: W,
    bestPracticeType: BestPractice.Type,
    endpointPath: String
) throws -> Audit? {
    var command = AuditRunCommand<W>()
    command.webService = webService

    let app = Application()
    try command.run(app: app)

    // Get the AuditInterfaceExporter
    let optionalExporter = app.interfaceExporters.first { exporter in
        exporter.typeErasedInterfaceExporter is AuditInterfaceExporter
    }
    let auditInterfaceExporter = try XCTUnwrap(optionalExporter?.typeErasedInterfaceExporter as? AuditInterfaceExporter)
    let audits = auditInterfaceExporter.report.audits
    let relevantAudit = audits.filter {
        type(of: $0.bestPractice) == bestPracticeType &&
        $0.endpoint.absolutePath.pathString == endpointPath
    }
    
    return relevantAudit.first
}

func assertNoFinding<W: WebService>(
    webService: W,
    bestPracticeType: BestPractice.Type,
    endpointPath: String
) throws {
    let audit = try getAudit(webService: webService, bestPracticeType: bestPracticeType, endpointPath: endpointPath)
    if let audit = audit {
        XCTAssertTrue(audit.findings.isEmpty)
    }
}

func assertOneFinding<F: Finding & Equatable, W: WebService>(
    webService: W,
    bestPracticeType: BestPractice.Type,
    endpointPath: String,
    expectedFinding: F
) throws {
    let audit = try XCTUnwrap(getAudit(webService: webService, bestPracticeType: bestPracticeType, endpointPath: endpointPath))
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
