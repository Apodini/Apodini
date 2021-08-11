//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
        #if os(Linux)
        throw XCTSkip("Skipped testHandlerCollection on Linux due to some undiscovered issues on focal nightly and xenial 5.4.2 builds")
        #endif

        for idx in 0..<100 {
            if idx > 0 {
                try tearDownWithError()
                try setUpWithError()
            }
            
            try TestWebService.start(app: app)
            
            let apodiniDeployIE = try XCTUnwrap(app.storage.get(ApodiniDeployInterfaceExporter.ApplicationStorageKey.self))
            let actual = apodiniDeployIE.collectedEndpoints
            
            let expected: [CollectedEndpointInfo] = [
                CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint<Text>(blackboard: MockBlackboard(
                        (EndpointSource<Text>.self, EndpointSource(handler: Text(""), context: Context())),
                        (AnyHandlerIdentifier.self, TestWebService.handler1Id))),
                    deploymentOptions: DeploymentOptions([
                        ResolvedOption(key: .memorySize, value: .mb(128)),
                        ResolvedOption(key: .timeout, value: .seconds(12))
                    ])
                ),
                CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint<Text>(blackboard: MockBlackboard(
                        (EndpointSource<Text>.self, EndpointSource(handler: Text(""), context: Context())),
                        (AnyHandlerIdentifier.self, TestWebService.handler2Id))),
                    deploymentOptions: DeploymentOptions([])
                ),
                CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint<Text>(blackboard: MockBlackboard(
                        (EndpointSource<Text>.self, EndpointSource(handler: Text(""), context: Context())),
                        (AnyHandlerIdentifier.self, TestWebService.handler3Id))),
                    deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(70)))
                ),
                CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint<Text>(blackboard: MockBlackboard(
                        (EndpointSource<Text>.self, EndpointSource(handler: Text(""), context: Context())),
                        (AnyHandlerIdentifier.self, TestWebService.handler4Id))),
                    deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(150)))
                ),
                CollectedEndpointInfo(
                    handlerType: HandlerTypeIdentifier(Text.self),
                    endpoint: Endpoint<Text>(blackboard: MockBlackboard(
                        (EndpointSource<Text>.self, EndpointSource(handler: Text(""), context: Context())),
                        (AnyHandlerIdentifier.self, TestWebService.handler5Id))),
                    deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(180)))
                )
            ]
            
            if !actual.compareIgnoringOrder(expected) {
                let missingEndpoints = Set(expected).subtracting(actual)
                let unexpectedEndpoints = Set(actual).subtracting(expected)
                let fmtEndpointInfoSet: (Set<CollectedEndpointInfo>) -> String = { set in
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
