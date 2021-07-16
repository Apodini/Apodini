//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import XCTApodini
import ApodiniREST
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
    func testExportWebServiceStructure() throws { // swiftlint:disable:this function_body_length
        let wsStructure = try StaticDeploymentProvider(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl
        ).readWebServiceStructure()
        
        XCTAssertEqual(wsStructure.enabledDeploymentProviders, [
            localhostDeploymentProviderId, lambdaDeploymentProviderId
        ])
        
        XCTAssertEqual(
            wsStructure.deploymentConfig,
            DeploymentConfig(defaultGrouping: .separateNodes, deploymentGroups: [
                .allHandlers(ofType: Text.self, groupId: "TextHandlersGroup"),
                .handlers(withIds: [
                    AnyHandlerIdentifier("0.0.0.0"),
                    AnyHandlerIdentifier("AWS_RandomNumberGenerator.main")
                ], groupId: "group_aws_rand"),
                .handlers(withIds: [
                    AnyHandlerIdentifier("0.1.0.0"),
                    AnyHandlerIdentifier("AWS_RandomNumberGenerator.other")
                ], groupId: "group_aws_rand2")
            ])
        )
        
        XCTAssertEqual(9, wsStructure.endpoints.count)
        
        XCTAssertEqualIgnoringOrder(wsStructure.endpoints, [
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("AWS_RandomNumberGenerator.main"),
                deploymentOptions: DeploymentOptions([
                    ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(150)),
                    ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
                ])
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("AWS_RandomNumberGenerator.other"),
                deploymentOptions: DeploymentOptions([
                    ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(180)),
                    ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
                ])
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "AWS_Greeter"),
                handlerId: AnyHandlerIdentifier("0.2.0"),
                deploymentOptions: DeploymentOptions([
                    ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(175)),
                    ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
                ])
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "LH_TextMut"),
                handlerId: AnyHandlerIdentifier("LH_TextMut.main"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "LH_Greeter"),
                handlerId: AnyHandlerIdentifier("0.4.0"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text2"),
                handlerId: AnyHandlerIdentifier("0.1.0.0"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text2"),
                handlerId: AnyHandlerIdentifier("0.0.0.0"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.5"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.6"),
                deploymentOptions: DeploymentOptions()
            )
        ])
    }
}
