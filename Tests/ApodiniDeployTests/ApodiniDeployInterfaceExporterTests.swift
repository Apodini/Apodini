//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-03-17.
//

import Foundation
import XCTest
@testable import Apodini
@testable import ApodiniDeploy
import XCTApodini
import ApodiniUtils


private struct TestWebService: Apodini.WebService {
    static let handler1Id = AnyHandlerIdentifier("handler1")
    static let handler2Id = AnyHandlerIdentifier("handler2")
    static let handler3Id = AnyHandlerIdentifier("handler3")
    static let handler4Id = AnyHandlerIdentifier("handler4")
    static let handler5Id = AnyHandlerIdentifier("handler5")
    
    var content: some Component {
        Text("")
            .identified(by: Self.handler1Id)
            .deploymentOptions(
                .memory(.mb(128)),
                .timeout(.seconds(12))
            )
        Group("a") {
            Text("")
                .operation(.read)
                .identified(by: Self.handler2Id)
            Text("")
                .operation(.create)
                .identified(by: Self.handler3Id)
                .deploymentOptions(
                    .memory(.mb(70))
                )
            Group("b") {
                Text("")
                    .operation(.read)
                    .identified(by: Self.handler4Id)
                    .deploymentOptions(.memory(.mb(70)))
                Text("")
                    .operation(.create)
                    .identified(by: Self.handler5Id)
                    .deploymentOptions(.memory(.mb(180)))
            }.deploymentOptions(
                .memory(.mb(150))
            )
        }
    }
    
    var configuration: Configuration {
        ApodiniDeploy()
    }
}


class ApodiniDeployInterfaceExporterTests: XCTApodiniTest {
    func testHandlerCollection() throws {
        guard !Self.isRunningOnLinuxDebug() else {
            return
        }
        
        for idx in 0..<100 {
            if idx > 0 {
                try tearDownWithError()
                try setUpWithError()
            }
            
            TestWebService.start(app: app)
            
            let apodiniDeployIE = try XCTUnwrap(app.storage.get(ApodiniDeployInterfaceExporter.ApplicationStorageKey.self))
            let actual = apodiniDeployIE.collectedEndpoints
            
            let expected: [ApodiniDeployInterfaceExporter.CollectedEndpointInfo] = [
                ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint(handler: Text(""), blackboard: MockBlackboard((AnyHandlerIdentifier.self, TestWebService.handler1Id))),
                    deploymentOptions: DeploymentOptions([
                        ResolvedOption(key: .memorySize, value: .mb(128)),
                        ResolvedOption(key: .timeout, value: .seconds(12))
                    ])
                ),
                ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint(handler: Text(""), blackboard: MockBlackboard((AnyHandlerIdentifier.self, TestWebService.handler2Id))),
                    deploymentOptions: DeploymentOptions([])
                ),
                ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint(handler: Text(""), blackboard: MockBlackboard((AnyHandlerIdentifier.self, TestWebService.handler3Id))),
                    deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(70)))
                ),
                ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint(handler: Text(""), blackboard: MockBlackboard((AnyHandlerIdentifier.self, TestWebService.handler4Id))),
                    deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(150)))
                ),
                ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint(handler: Text(""), blackboard: MockBlackboard((AnyHandlerIdentifier.self, TestWebService.handler5Id))),
                    deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(180)))
                )
            ]
            
            if !actual.compareIgnoringOrder(expected) {
                let missingEndpoints = Set(expected).subtracting(actual)
                let unexpectedEndpoints = Set(actual).subtracting(expected)
                let fmtEndpointInfoSet: (Set<ApodiniDeployInterfaceExporter.CollectedEndpointInfo>) -> String = { set in
                    set
                        .map { "  - HT: \($0.handlerType), id: \($0.endpoint[AnyHandlerIdentifier.self]), #opts: \($0.deploymentOptions.count)" }
                        .joined(separator: "\n")
                }
                XCTFail(
                    """
                    collectedEndpoints property did not match expected value:
                    - missing endpoints:
                    \(fmtEndpointInfoSet(missingEndpoints))
                    - unexpected endpoints:
                    \(fmtEndpointInfoSet(unexpectedEndpoints))
                    """
                )
            }
        }
    }
}
