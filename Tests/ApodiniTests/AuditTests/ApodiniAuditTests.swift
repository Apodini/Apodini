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


final class ApodiniAuditTests: ApodiniTests {
    struct TestWebService: WebService {
        var content: some Component {
            Group("crudGet", "looooooooooooooooooooooooooooooooooongSeg2", "withextension.html/") {
                SomeComp()
            }
        }

        var configuration: Configuration {
            REST {
                // swiftlint:disable:next all
                if 1 == 1 {
                    APIAuditor()
                }
                if Int.random(in: 1...2) == 1 {
                    APIAuditor()
                } else {
                    APIAuditor()
                }
            }
        }
    }
    
    struct SomeComp: Handler {
        func handle() -> String {
            "Test"
        }
    }

    func testBasicAuditing() throws {
        let commandType = AuditRunCommand<TestWebService>.self
        var command = commandType.init()
        command.webService = .init()
        
        try command.run(app: app)
        
        // Get the AuditInterfaceExporter
        // FUTURE We just get the first one, for now we do not consider the case of multiple exporters
        let optionalExporter = app.interfaceExporters.first { exporter in
            exporter.typeErasedInterfaceExporter is AuditInterfaceExporter
        }
        let auditInterfaceExporter = try XCTUnwrap(optionalExporter?.typeErasedInterfaceExporter as? AuditInterfaceExporter)
        
        let auditReports = auditInterfaceExporter.audits.flatMap { $0.reports }
        
        let expectedAuditReports = [
//            AuditReport(
//                message: "The path segments do not contain any underscores",
//                auditResult: .success
//            ),
            AuditReport(
                message: "The path segment \"looooooooooooooooooooooooooooooooooongSeg2\" is too short or too long",
                auditResult: .fail
            ),
            AuditReport(
                message: "The path segment crudGet contains one or more CRUD verbs!",
                auditResult: .fail
            ),
            AuditReport(
                message: "\"crudGet\" and \"looooooooooooooooooooooooooooooooooongSeg2\" are not related!",
                auditResult: .fail
            ),
            AuditReport(
                message: "\"looooooooooooooooooooooooooooooooooongSeg2\" and \"withextension.html\" are not related!",
                auditResult: .fail
            ),
            AuditReport(
                message: "The path segment crudGet contains one or more uppercase letters!",
                auditResult: .fail
            ),
            AuditReport(
                message: "The path segment looooooooooooooooooooooooooooooooooongSeg2 contains one or more uppercase letters!",
                auditResult: .fail
            ),
            AuditReport(
                message: "The path segment withextension.html has a file extension.",
                auditResult: .fail
            )
        ]
        
        XCTAssertEqualIgnoringOrder(auditReports, expectedAuditReports)
    }
    
    func testRegisterCommandOnce() throws {
        let webService = TestWebService()
        
        try TestWebService.start(mode: .boot, app: app, webService: webService)
        let commands = webService.configuration._commands
        
        XCTAssertEqual(commands.count, 1)
    }
}
