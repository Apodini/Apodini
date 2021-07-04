//
//  WebServiceStructureExportTests.swift
//  
//
//  Created by Lukas Kollmer on 2021-03-17.
//

import Foundation
import XCTApodini
import ApodiniREST
import ApodiniOpenAPI
import ApodiniUtils
@testable import ApodiniDeploy
@testable import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostRuntime
import DeploymentTargetLocalhostCommon
import DeploymentTargetAWSLambdaCommon


private struct TestWebService: Apodini.WebService {
    var content: some Component {
        Text("a")
            .identified(by: "Handler1")
        Group("api") {
            Text("b")
                .identified(by: "Handler2")
                .deploymentOptions(
                    .memory(.mb(175)),
                    .timeout(.seconds(12))
                )
        }
    }
    
    var configuration: Configuration {
        REST {
            OpenAPI()
        }
        ApodiniDeploy(
            runtimes: [LocalhostRuntime.self],
            config: DeploymentConfig(
                defaultGrouping: .separateNodes,
                deploymentGroups: [
                    .allHandlers(ofType: Text.self, groupId: "TextHandlersGroup")
                ]
            )
        )
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

extension DeploymentProvider {
    func testableWebServiceStructureRetrieval() throws -> WebServiceStructure {
        let service = TestWebService()
        service.runSyntaxTreeVisitor()
        return try retrieveWebServiceStructure()
    }
}

class WebServiceStructureExportTests: ApodiniDeployTestCase {
    func testExportWebServiceStructure() throws { // swiftlint:disable:this function_body_length
        let wsStructure = try StaticDeploymentProvider(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl
        ).testableWebServiceStructureRetrieval()
        
        XCTAssertEqual(wsStructure.enabledDeploymentProviders, [
            localhostDeploymentProviderId
        ])

        XCTAssertEqual(
            wsStructure.deploymentConfig,
            DeploymentConfig(defaultGrouping: .separateNodes, deploymentGroups: [
                .allHandlers(ofType: Text.self, groupId: "TextHandlersGroup")
            ])
        )
        
        XCTAssertEqual(2, wsStructure.endpoints.count)

        XCTAssertEqualIgnoringOrder(wsStructure.endpoints, [
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("Handler2"),
                deploymentOptions: DeploymentOptions([
                    ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(175)),
                    ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
                ])
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Test"),
                handlerId: AnyHandlerIdentifier("Handler1"),
                deploymentOptions: DeploymentOptions([])
            )
        ])
    }
}
