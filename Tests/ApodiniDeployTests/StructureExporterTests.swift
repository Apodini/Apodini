//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//    

import Foundation
@testable import Apodini
import ArgumentParser
import ApodiniUtils
@testable import ApodiniDeploy
@testable import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport
import XCTest


private struct TestWebService: Apodini.WebService {
    var content: some Component {
        Group("test123") {
            Text("abc")
        }.formDeploymentGroup(withId: "myID")
            
        Group("api") {
            Text("b")
        }.formDeploymentGroup(withId: "apiID")
    }
    
    var configuration: Configuration {
        ApodiniDeploy(runtimes: [TestRuntime.self])
    }
}


private class TestRuntime: DeploymentProviderRuntime {
    static var identifier: DeploymentProviderID {
        DeploymentProviderID("de.apodini.ApodiniDeploymentProvider.test")
    }
    
    required init(deployedSystem: AnyDeployedSystem, currentNodeId: DeployedSystemNode.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
    }
    
    var deployedSystem: AnyDeployedSystem
    
    var currentNodeId: DeployedSystemNode.ID
    
    static var exportCommand: StructureExporter.Type {
        TestExportCommand.self
    }
    
    static var startupCommand: DeploymentStartupCommand.Type {
        TestStartupCommand.self
    }
    
    func configure(_ app: Application) throws {}
    
    func handleRemoteHandlerInvocation<H>(_ invocation: HandlerInvocation<H>) throws ->
        RemoteHandlerInvocationRequestResponse<H.Response.Content> where H: InvocableHandler {
            .invokeDefault(url: .init(fileURLWithPath: #filePath))
    }
}

private struct TestExportCommand: StructureExporter {
    init() {
        self.filePath = StructureExporterTests.modelFileUrl.path
        self.identifier = TestRuntime.identifier.rawValue
    }
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "test")
    }

    var filePath: String
    var identifier: String
    
    func run() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        try TestWebService.start(mode: .startup, app: app, webService: TestWebService())
    }
}

private struct TestStartupCommand: DeploymentStartupCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "test")
    }
    
    @Argument
    var filePath: String
    
    @Argument
    var nodeId: String
    
    var deployedSystemType: AnyDeployedSystem.Type {
        DeployedSystem.self
    }
    
    
    func run() throws {
        let app = Application()
        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try TestWebService.start(mode: .run, app: app)
    }
}


class StructureExporterTests: ApodiniDeployTestCase {
    static var modelFileUrl: URL {
        Self.productsDirectory.appendingPathComponent("tmp-ws-structure.json")
    }
    
    func testStructureExporter() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: TestExportCommand())
        TestWebService().start(app: app)
        // Test if file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: Self.modelFileUrl.path), "Modelfile not found")
        
        let data = try Data(contentsOf: Self.modelFileUrl, options: [])
        // Test if its decodable to expected Type
        let deployedSystem = try JSONDecoder().decode(DeployedSystem.self, from: data)
        
        XCTAssertEqual(deployedSystem.deploymentProviderId, TestRuntime.identifier)
        let expectedNodes: [DeployedSystemNode] = [
            DeployedSystemNode(
                id: "myID",
                exportedEndpoints: [
                    ExportedEndpoint(
                        handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                        handlerId: AnyHandlerIdentifier("0.0.0")
                    )
                ]
            ),
            DeployedSystemNode(
                id: "apiID",
                exportedEndpoints: [
                    ExportedEndpoint(
                        handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                        handlerId: AnyHandlerIdentifier("0.1.0")
                    )
                ]
            )
        ]
        
        XCTAssertEqualIgnoringOrder(deployedSystem.nodes, expectedNodes)
        
        // DeployedSystem methods
        let node = try XCTUnwrap(deployedSystem.node(withId: "myID"))
        XCTAssertEqual(node, expectedNodes[0])
        
        let exportingHandlerIdNode = try XCTUnwrap(
            deployedSystem.nodeExportingEndpoint(
                withHandlerId: AnyHandlerIdentifier("0.1.0")
            )
        )
        XCTAssertEqual(exportingHandlerIdNode, expectedNodes[1])
        
        app.shutdown()
    }
    
    func testWSStartForStructureExporters() {
        let instance = TestWebService()
        let application = Application()
        XCTAssertNoThrow(try instance.start(mode: .startup, app: application))
    }
}
