//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import XCTApodini
@testable import Apodini
import ApodiniREST
import OpenAPIKit
import ApodiniOpenAPI
import ApodiniUtils
@testable import ApodiniDeploy
@testable import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostCommon
import DeploymentTargetAWSLambdaCommon


private struct TestWebService: Apodini.WebService {
    var content: some Component {
        Text("a")
        Group("api") {
            Text("b")
        }
    }
    
    var configuration: Configuration {
        REST {
            OpenAPI()
        }
        ApodiniDeploy()
    }
}


/// A deployment provider which operates on an already-compiled executable, and
/// launches child processes out-of-process (this is important for the deployment provider to work in xctests).
private struct StaticDeploymentProvider: DeploymentProvider {
    static let identifier = DeploymentProviderID("de.lukaskollmer.staticApodiniDeploymentProvider")
    
    let executableUrl: URL
    
    var target: DeploymentProviderTarget {
        .executable(executableUrl)
    }
    
    var launchChildrenInCurrentProcessGroup: Bool { false }
}


class WebServiceStructureExportTests: ApodiniDeployTestCase {
    func testExportLambdaDeployedSystem() throws { // swiftlint:disable:this function_body_length
        let (_, deployedSystem) = try StaticDeploymentProvider(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl
        )
        .retrieveSystemStructure(
            Self.apodiniDeployTestWebServiceTargetUrl,
            providerCommand: "aws",
            additionalCommands: [
                "--identifier",
                StaticDeploymentProvider.identifier.rawValue,
                "--aws-api-gateway-api-id",
                "_createNew",
                "--aws-region",
                "eu-central-1"
            ], as: LambdaDeployedSystem.self)
        
        let exportedEndpoints = deployedSystem.nodes
            .flatMap { $0.exportedEndpoints }
        
        XCTAssertEqual(9, exportedEndpoints.count)
        
        XCTAssertEqualIgnoringOrder(exportedEndpoints, [
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("AWS_RandomNumberGenerator.main")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("AWS_RandomNumberGenerator.other")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_Greeter"),
                handlerId: AnyHandlerIdentifier("0.2.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "LH_TextMut"),
                handlerId: AnyHandlerIdentifier("LH_TextMut.main")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "LH_Greeter"),
                handlerId: AnyHandlerIdentifier("0.4.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text2"),
                handlerId: AnyHandlerIdentifier("0.1.0.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text2"),
                handlerId: AnyHandlerIdentifier("0.0.0.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.5")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.6")
            )
        ])
    }
    
    func testExportLocalHostDeployedSystem() throws { // swiftlint:disable:this function_body_length
        let (_, deployedSystem) = try StaticDeploymentProvider(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl
        )
        .retrieveSystemStructure(
            Self.apodiniDeployTestWebServiceTargetUrl,
            providerCommand: "local",
            additionalCommands: [
                "--identifier",
                StaticDeploymentProvider.identifier.rawValue,
                "--endpoint-processes-base-port",
                "5000"
            ], as: LocalhostDeployedSystem.self)
        
        let exportedEndpoints = deployedSystem.nodes
            .flatMap { $0.exportedEndpoints }
        
        XCTAssertEqual(9, exportedEndpoints.count)
        
        XCTAssertEqualIgnoringOrder(exportedEndpoints, [
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("AWS_RandomNumberGenerator.main")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("AWS_RandomNumberGenerator.other")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_Greeter"),
                handlerId: AnyHandlerIdentifier("0.2.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "LH_TextMut"),
                handlerId: AnyHandlerIdentifier("LH_TextMut.main")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "LH_Greeter"),
                handlerId: AnyHandlerIdentifier("0.4.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text2"),
                handlerId: AnyHandlerIdentifier("0.1.0.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text2"),
                handlerId: AnyHandlerIdentifier("0.0.0.0")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.5")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.6")
            )
        ])
    }
    
    func testExportIoTDeployedSystem() throws { // swiftlint:disable:this function_body_length
        let (_, deployedSystem) = try StaticDeploymentProvider(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl
        )
        .retrieveSystemStructure(
            Self.apodiniDeployTestWebServiceTargetUrl,
            providerCommand: "iot",
            additionalCommands: [
                "--ip-address",
                "0.0.0.0",
                "--action-keys",
                "deployTest"
            ], as: DeployedSystem.self)
        
        let exportedEndpoints = deployedSystem.nodes
            .flatMap { $0.exportedEndpoints }
        XCTAssert(!deployedSystem.nodes.isEmpty)
        let node = try XCTUnwrap(deployedSystem.nodes.first)
        XCTAssertEqual("0.0.0.0", node.id)
        
        XCTAssertEqual(2, exportedEndpoints.count)
        XCTAssertEqualIgnoringOrder(exportedEndpoints, [
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.5")
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.6")
            )
        ])
    }
}
