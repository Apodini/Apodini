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
            Group("crudGet", "ooooooaaaaaaooooooaaaaaaooooooaaaaaa", "withextension.html") {
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
            
            AuditConfiguration {
                AppropriateLengthForURLPathSegmentsConfiguration(
                    maximumLength: 50
                )
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
        
        let auditFindings = auditInterfaceExporter.reports.flatMap { $0.findings }
        
        let expectedAuditFindings = [
//            AuditFinding(
//                message: "The path segments do not contain any underscores",
//                result: .success
//            ),
//            AuditFinding(
//                message: "The path segment \"looooooooooooooooooooooooooooooooooongSeg2\" is too short or too long",
//                result: .fail
//            ),
            AuditFinding(
                message: "The path segment crudGet contains one or more CRUD verbs!",
                result: .fail
            ),
            AuditFinding(
                message: "\"crudGet\" and \"ooooooaaaaaaooooooaaaaaaooooooaaaaaa\" are not related!",
                result: .fail
            ),
            AuditFinding(
                message: "\"ooooooaaaaaaooooooaaaaaaooooooaaaaaa\" and \"withextension.html\" are not related!",
                result: .fail
            ),
            AuditFinding(
                message: "The path segment crudGet contains one or more uppercase letters!",
                result: .fail
            ),
//            AuditFinding(
//                message: "The path segment looooooooooooooooooooooooooooooooooongSeg2 contains one or more uppercase letters!",
//                result: .fail
//            ),
            AuditFinding(
                message: "The path segment withextension.html has a file extension.",
                result: .fail
            )
        ]
        
        XCTAssertSetEqual(auditFindings, expectedAuditFindings)
    }
    
    func testRegisterCommandOnce() throws {
        let webService = TestWebService()
        
        try TestWebService.start(mode: .boot, app: app, webService: webService)
        let commands = webService.configuration._commands
        
        // Filter to get only auditcommands
        let auditCommands = commands.filter { cmd in
            cmd is AuditCommand<TestWebService>.Type
        }
        
        XCTAssertEqual(auditCommands.count, 1)
    }
}

func XCTAssertSetEqual<T: Hashable>(
    _ actual: [T],
    _ expected: [T],
    _ message: @autoclosure () -> String = "" ,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let actualCounts = actual.distinctElementCounts()
    let expectedCounts = expected.distinctElementCounts()
    if actualCounts == expectedCounts {
        return
    }
    
    // Build sets
    let actualSet = Set(actual)
    let expectedSet = Set(expected)
    
    if actualSet.count != actual.count || expectedSet.count != expected.count {
        XCTFail("The expected or actual array is not duplicate-free!", file: file, line: line)
    }
    
    let missingElements = expectedSet.subtracting(actualSet)
    let superfluousElements = actualSet.subtracting(expectedSet)
    
    var failureMsg = ""
    if !missingElements.isEmpty {
        failureMsg += "Missing elements:\n\(missingElements.map { "- \($0)" }.joined(separator: "\n"))\n"
    }
    if !superfluousElements.isEmpty {
        failureMsg += "Superfluous elements:\n\(superfluousElements.map { "- \($0)" }.joined(separator: "\n"))\n"
    }
    let customMsg = message()
    if !customMsg.isEmpty {
        failureMsg.append(customMsg)
    }
    XCTFail(failureMsg, file: file, line: line)
}
