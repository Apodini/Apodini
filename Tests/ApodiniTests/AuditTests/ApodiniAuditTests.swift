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
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Run the AuditSetupCommand. It doesn't matter which WebService we specify.
        let commandType = AuditSetupNLTKCommand<AuditableWebService>.self
        var command = commandType.init()
        try command.run(app: app)
        print("Installing")
    }
    
    struct AuditableWebService: WebService {
        var content: some Component {
            Group("crudGet", "ooooooaaaaaaooooooaaaaaaooooooaaaaaa", "withextension.html") {
                SomeHandler()
            }
        }

        @ConfigurationBuilder static var conf: Configuration {
            REST {
                // swiftlint:disable:next all
                if 1 == 1 {
                    APIAuditor {
                        AppropriateLengthForURLPathSegmentsConfiguration(
                            maximumLength: 50
                        )
                        CustomBPConfig()
                    }
                }
            }
        }
        
        var configuration: Configuration {
            Self.conf
        }
    }
    
    struct AuditableWebService2: WebService {
        var content: some Component {
            Group("getThisResource") {
                SomeHandler()
            }
            Group("testGreetings") {
                SomePOSTHandler()
                DELETEComponent()
            }
            Group("testGreeting") {
                SomePOSTHandler()
            }
        }
        
        var configuration: Configuration {
            AuditableWebService.conf
        }
        
//        var metadata: AnyWebServiceMetadata {
//            SelectBestPractices(.exclude, .all)
//        }
    }
    
    struct DELETEComponent: Component {
        @PathParameter var greetingID: UUID
        
        var content: some Component {
            Group($greetingID) {
                SomeDELETEHandler(greetingID: $greetingID)
            }
        }
    }
    
    struct SomeHandler: Handler {
        func handle() -> Response<String> {
            .final(information: ETag("aosidhaoshid"))
        }
        
        var metadata: AnyHandlerMetadata {
            SelectBestPractices(.include, .urlPath)
        }
    }
    
    struct SomePOSTHandler: Handler {
        func handle() -> String {
            "Hello"
        }
        
        var metadata: AnyHandlerMetadata {
            Operation(.create)
            Pattern(.requestResponse)
        }
    }
    
    struct SomeDELETEHandler: Handler {
        @Binding var greetingID: UUID
        
        func handle() -> String {
            "Hello"
        }
        
        var metadata: AnyHandlerMetadata {
            Operation(.delete)
        }
    }
    
    struct CustomBPConfig: BestPracticeConfiguration {
        func configureBestPractice() -> BestPractice {
            CustomBP()
        }
    }
    
    struct CustomBP: BestPractice {
        func check(into audit: Audit, _ app: Application) {
            print("custom best practice!")
        }
        
        static var scope: BestPracticeScopes = .all
        static var category: BestPracticeCategories = .method
    }

    func testBasicAuditing() throws {
        let commandType = AuditRunCommand<AuditableWebService>.self
        var command = commandType.init()
        
        let audits = try getAuditsForAuditRunCommand(&command)
        let actualFindings = audits.flatMap { $0.findings }
        
        let expectedFindings = [
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
            Finding(
                message: "The path segment crudGet contains one or more CRUD verbs!",
                assessment: .fail
            ),
            Finding(
                message: "\"crudGet\" and \"ooooooaaaaaaooooooaaaaaaooooooaaaaaa\" are not related!",
                assessment: .fail
            ),
            Finding(
                message: "\"ooooooaaaaaaooooooaaaaaaooooooaaaaaa\" and \"withextension.html\" are not related!",
                assessment: .fail
            ),
            Finding(
                message: "The path segment crudGet contains one or more uppercase letters!",
                assessment: .fail
            ),
            Finding(
                message: "The path segment withextension.html has a file extension.",
                assessment: .fail
            )
        ]
        
        XCTAssertSetEqual(actualFindings, expectedFindings)
    }
    
    func testLingusticAuditing() throws {
        let commandType = AuditRunCommand<AuditableWebService2>.self
        var command = commandType.init()
        
        let audits = try getAuditsForAuditRunCommand(&command)
        
        let lingAudits = audits.filter { type(of: $0.bestPractice).category.contains(.linguistic) }
        let lingFindings = lingAudits.flatMap { $0.findings }
        
        let expectedLingFindings = [
            Finding(
                message: "\"Greeting\" is not a plural noun for a POST handler",
                assessment: .fail
            ),
            Finding(
                message: "\"Greetings\" is a plural noun for a POST handler",
                assessment: .pass
            ),
            Finding(
                message: "\"ID\" is a singular noun for a PUT or DELETE handler",
                assessment: .pass
            )
        ]
        
        XCTAssertSetEqual(lingFindings, expectedLingFindings)
    }
    
    func testSelectingBestPractices() throws {
        let commandType = AuditRunCommand<AuditableWebService2>.self
        var command = commandType.init()
        
        let audits = try getAuditsForAuditRunCommand(&command)
        
        XCTAssertTrue(audits.contains {
            $0.findings.contains {
                $0.message.contains("getThisResource")
            }
        })
    }
    
    func getAuditsForAuditRunCommand<T: WebService>(_ command: inout AuditRunCommand<T>) throws -> [Audit] {
        command.webService = .init()
        
        try command.run(app: app)
        
        // Get the AuditInterfaceExporter
        // FUTURE We just get the first one, for now we do not consider the case of multiple exporters
        let optionalExporter = app.interfaceExporters.first { exporter in
            exporter.typeErasedInterfaceExporter is AuditInterfaceExporter
        }
        let auditInterfaceExporter = try XCTUnwrap(optionalExporter?.typeErasedInterfaceExporter as? AuditInterfaceExporter)
        
        return auditInterfaceExporter.report.audits
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
