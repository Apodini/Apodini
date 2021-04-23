//
//  File.swift
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
        ExporterConfiguration()
            .exporter(RESTInterfaceExporter.self)
            .exporter(OpenAPIInterfaceExporter.self)
            .exporter(ApodiniDeployInterfaceExporter.self)
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
    func testExportWebServiceStructure() throws {
        let wsStructure = try StaticDeploymentProvider(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl
        ).readWebServiceStructure()
        
        XCTAssertEqual(wsStructure.enabledDeploymentProviders, [
            localhostDeploymentProviderId, lambdaDeploymentProviderId
        ])
        
        XCTAssertEqual(
            wsStructure.deploymentConfig,
            DeploymentConfig(defaultGrouping: .singleNode, deploymentGroups: [
                .handlers(withIds: [
                    AnyHandlerIdentifier("0.2.0")
                ], groupId: "greeter"),
                .handlers(withIds: [
                    AnyHandlerIdentifier("RandomNumberGenerator.main"),
                    AnyHandlerIdentifier("0.0.0.0")
                ], groupId: "rand"),
                .handlers(withIds: [
                    AnyHandlerIdentifier("RandomNumberGenerator.other"),
                    AnyHandlerIdentifier("0.1.0.0")
                ], groupId: "rand2")
            ])
        )
        
        XCTAssertEqual(5, wsStructure.endpoints.count)
        
        XCTAssertEqualIgnoringOrder(wsStructure.endpoints, [
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Greeter"),
                handlerId: AnyHandlerIdentifier("0.2.0"),
                deploymentOptions: DeploymentOptions([
                    ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(175)),
                    ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
                ])
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("RandomNumberGenerator.main"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "RandomNumberGenerator"),
                handlerId: AnyHandlerIdentifier("RandomNumberGenerator.other"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.1.0.0"),
                deploymentOptions: DeploymentOptions()
            ),
            ExportedEndpoint(
                handlerType: HandlerTypeIdentifier(rawValue: "Text"),
                handlerId: AnyHandlerIdentifier("0.0.0.0"),
                deploymentOptions: DeploymentOptions()
            )
        ])
    }
}
