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
    struct AuditableWebService: WebService {
        var content: some Component {
            Group("crudGet", "ooooooaaaaaaooooooaaaaaaooooooaaaaaa", "withextension.html") {
                SomeComp()
            }
        }

        @ConfigurationBuilder static var conf: Configuration {
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
        
        var configuration: Configuration {
            Self.conf
        }
    }
    
    struct AuditableWebService2: WebService {
        var content: some Component {
            Group("getThisResource") {
                SomeComp()
            }
            Group("testGreetings") {
                SomePOSTComp()
                DELETEComponent()
            }
            Group("testGreeting") {
                SomePOSTComp()
            }
        }
        
        var configuration: Configuration {
            AuditableWebService.conf
        }
    }
    
    struct DELETEComponent: Component {
        @PathParameter var greetingID: UUID
        
        var content: some Component {
            Group($greetingID) {
                SomeDELETEComp(greetingID: $greetingID)
            }
        }
    }
    
    struct SomeComp: Handler {
        func handle() -> String {
            "Test"
        }
    }
    
    struct SomePOSTComp: Handler {
        func handle() -> String {
            "Hello"
        }
        
        var metadata: AnyHandlerMetadata {
            Operation(.create)
        }
    }
    
    struct SomeDELETEComp: Handler {
        @Binding var greetingID: UUID
        
        func handle() -> String {
            "Hello"
        }
        
        var metadata: AnyHandlerMetadata {
            Operation(.delete)
        }
    }

    func testBasicAuditing() throws {
        let commandType = AuditRunCommand<AuditableWebService>.self
        var command = commandType.init()
        
        let reports = try getReportsForAuditRunCommand(&command)
        let actualAuditFindings = reports.flatMap { $0.findings }
        
        let expectedAuditFindings = [
//            AuditFinding(
//                message: "The path segments do not contain any underscores",
//                result: .success
//            ),
//            AuditFinding(
//                message: "The path segment \"looooooooooooooooooooooooooooooooooongSeg2\" is too short or too long",
//                result: .fail
//            ),
//            AuditFinding(
//                message: "The path segment looooooooooooooooooooooooooooooooooongSeg2 contains one or more uppercase letters!",
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
            AuditFinding(
                message: "The path segment withextension.html has a file extension.",
                result: .fail
            )
        ]
        
        XCTAssertSetEqual(actualAuditFindings, expectedAuditFindings)
    }
    
    func testLingusticAuditing() throws {
        let commandType = AuditRunCommand<AuditableWebService2>.self
        var command = commandType.init()
        
        let reports = try getReportsForAuditRunCommand(&command)
        
        let lingReports = reports.filter { $0.bestPractice.category.contains(.linguistic) }
        let lingAudits = lingReports.flatMap { $0.findings }
        
        let expectedLingAudits = [
            AuditFinding(
                message: "\"Greeting\" is not a plural noun for a POST handler",
                result: .fail
            ),
            AuditFinding(
                message: "\"Greetings\" is a plural noun for a POST handler",
                result: .success
            ),
            AuditFinding(
                message: "\"ID\" is a singular noun for a PUT or DELETE handler",
                result: .success
            )
        ]
        
        XCTAssertSetEqual(lingAudits, expectedLingAudits)
    }
    
    func getReportsForAuditRunCommand<T: WebService>(_ command: inout AuditRunCommand<T>) throws -> [AuditReport] {
        command.webService = .init()
        
        try command.run(app: app)
        
        // Get the AuditInterfaceExporter
        // FUTURE We just get the first one, for now we do not consider the case of multiple exporters
        let optionalExporter = app.interfaceExporters.first { exporter in
            exporter.typeErasedInterfaceExporter is AuditInterfaceExporter
        }
        let auditInterfaceExporter = try XCTUnwrap(optionalExporter?.typeErasedInterfaceExporter as? AuditInterfaceExporter)
        
        return auditInterfaceExporter.reports
    }
    
    func testRegisterCommandOnce() throws {
        let webService = AuditableWebService()
        
        try AuditableWebService.start(mode: .boot, app: app, webService: webService)
        let commands = webService.configuration._commands
        
        // Filter to get only auditcommands
        let auditCommands = commands.filter { cmd in
            cmd is AuditCommand<AuditableWebService>.Type
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
