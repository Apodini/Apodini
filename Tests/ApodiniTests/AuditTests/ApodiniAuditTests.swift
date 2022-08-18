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
    override class func setUp() {
        // Run the AuditSetupCommand. It doesn't matter which WebService we specify.
        let app = Application()
        let commandType = AuditSetupNLTKCommand<AuditableWebService>.self
        let command = commandType.init()
        do {
            try command.run(app: app)
            print("Installed requirements!")
        } catch {
            print("Could not install requirements: \(error)")
        }
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
                        URLPathSegmentLengthConfiguration(
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
        @PathParameter var someId: UUID
        
        var content: some Component {
            Group("getThisResource") {
                SomeHandler()
            }
            Group("testGreetings", $someId) {
                SomePOSTHandler(whateverId: $someId)
                Group("delete") {
                    SomeDELETEHandler(greetingID: $someId)
                }
            }
            Group("testGreeting", $someId) {
                SomePOSTHandler(whateverId: $someId)
            }
        }
        
        var configuration: Configuration {
            AuditableWebService.conf
        }
        
//        var metadata: AnyWebServiceMetadata {
//            SelectBestPractices(.exclude, .all)
//        }
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
        @Binding var whateverId: UUID
        
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
        func configure() -> BestPractice {
            CustomBP()
        }
    }
    
    class CustomBP: BestPractice {
        func check(into audit: Audit, _ app: Application) {
            print("custom best practice!")
        }
        
        required init() { }
        
        static var scope: BestPracticeScopes = .all
        static var category: BestPracticeCategories = .httpMethod
    }

    func testBasicAuditing() throws {
        let commandType = AuditRunCommand<AuditableWebService>.self
        var command = commandType.init()
        
        let audits = try getAuditsForAuditRunCommand(&command)
        let actualFindings = audits.flatMap { $0.findings }
        
        let expectedFindings: [Finding] = [
//            AuditFinding(
//                diagnosis: "The path segments do not contain any underscores",
//                result: .success
//            ),
//            AuditFinding(
//                diagnosis: "The path segment \"looooooooooooooooooooooooooooooooooongSeg2\" is too short or too long",
//                result: .violation
//            ),
//            AuditFinding(
//                diagnosis: "The path segment looooooooooooooooooooooooooooooooooongSeg2 contains one or more uppercase letters!",
//                result: .violation
//            ),
            URLCRUDVerbsFinding.crudVerbFound(segment: "crudGet"),
            LowercasePathSegmentsFinding.uppercaseCharacterFound(segment: "crudGet"),
            URLFileExtensionFinding.fileExtensionFound(segment: "withextension.html"),
            NumberOrSymbolsInURLFinding.nonLetterCharacterFound(segment: "withextension.html")
        ]
        
        XCTAssertFindingsEqual(actualFindings, expectedFindings)
    }
    
    func testLingusticAuditing() throws {
        let commandType = AuditRunCommand<AuditableWebService2>.self
        var command = commandType.init()
        
        let audits = try getAuditsForAuditRunCommand(&command)
        
        let lingAudits = audits.filter { type(of: $0.bestPractice).category.contains(.linguistic) }
        let lingFindings = lingAudits.flatMap { $0.findings }
        
        let expectedLingFindings: [BadCollectionSegmentName] = [
            //BadCollectionSegmentName.nonPluralBeforeParameter("Greeting")
        ]
        
        XCTAssertFindingsEqual(lingFindings, expectedLingFindings)
    }
    
    func testSelectingBestPractices() throws {
        let commandType = AuditRunCommand<AuditableWebService2>.self
        var command = commandType.init()
        
        let audits = try getAuditsForAuditRunCommand(&command)
        
        XCTAssertTrue(audits.contains {
            $0.findings.contains {
                $0.diagnosis.contains("getThisResource")
            }
        })
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
    
    private func getAuditsForAuditRunCommand<T: WebService>(_ command: inout AuditRunCommand<T>) throws -> [Audit] {
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
}

private struct FindingMessage: Hashable {
    let diagnosis: String
    let suggestion: String?
    let priority: Priority
    
    init(_ diagnosis: String, _ suggestion: String?, _ priority: Priority) {
        self.diagnosis = diagnosis
        self.suggestion = suggestion
        self.priority = priority
    }
}

func XCTAssertFindingsEqual(_ actual: [Finding], _ expected: [Finding]) {
    let actualMessages = actual.map { finding in
        FindingMessage(finding.diagnosis, finding.suggestion, finding.priority)
    }
    
    let expectedMessages = expected.map { finding in
        FindingMessage(finding.diagnosis, finding.suggestion, finding.priority)
    }
    
    XCTAssertSetEqual(actualMessages, expectedMessages)
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
