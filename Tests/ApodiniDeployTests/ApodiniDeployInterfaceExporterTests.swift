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
        ExporterConfiguration()
            .exporter(ApodiniDeployInterfaceExporter.self)
    }
}



class ApodiniDeployInterfaceExporterTests: XCTApodiniTest {
    
    func testHandlerCollection() throws {
        
        do {
            let optA1 = ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(125))
            let optA2 = ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(125))
//            do {
//                let tests: [Bool] = (0..<1000).map { _ in optA1.testEqual(optA2) }
//                XCTAssertEqual(1, Set(tests).count)
//                XCTAssertEqual(true, tests[0])
//            }
            
            let optB1 = ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
            let optB2 = ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
            
            let opts1 = DeploymentOptions([optA1, optB1])
            let opts2 = DeploymentOptions([optA2, optB2])
            
            let tests: [Bool] = (0...10_000).map { _ in
                opts1.reduced().options.compareIgnoringOrder(
                    opts2.reduced().options,
                    computeHash: { option, hasher in hasher.combine(option) },
                    areEqual: { lhs, rhs in lhs.testEqual(rhs) }
                )
            }
            
            if Set(tests).count != 1 || !tests[0] {
                fatalError()
            }
            
            XCTAssertEqual(1, Set(tests).count)
            XCTAssertTrue(tests[0])
            
        }
        
//        return;
        
        
        /*
         
         lhs = [(
            ResolvedOption<DeploymentOptionsNamespace>(
                key: OptionKeyWithDefaultValue<DeploymentOptionsNamespace, BuiltinDeploymentOptionsNamespace, TimeInterval>('DeploymentOptions:org.apodini.timeout'),
                value: TimeInterval(rawValue: 12)),
            1
         ), (
            ResolvedOption<DeploymentOptionsNamespace>(
                key: OptionKeyWithDefaultValue<DeploymentOptionsNamespace, BuiltinDeploymentOptionsNamespace, MemorySize>('DeploymentOptions:org.apodini.memorySize'),
                value: MemorySize(rawValue: 125)),
            1
         )]
         
         rhs = [(
            ResolvedOption<DeploymentOptionsNamespace>(
                key: OptionKeyWithDefaultValue<DeploymentOptionsNamespace, BuiltinDeploymentOptionsNamespace, MemorySize>('DeploymentOptions:org.apodini.memorySize'),
                value: MemorySize(rawValue: 125)),
            1
         ), (
            ResolvedOption<DeploymentOptionsNamespace>(
                key: OptionKeyWithDefaultValue<DeploymentOptionsNamespace, BuiltinDeploymentOptionsNamespace, TimeInterval>('DeploymentOptions:org.apodini.timeout'),
                value: TimeInterval(rawValue: 12)),
            1
         )]
         
         */
        
        TestWebService.main(app: app)
        
        let apodiniDeployIE = try XCTUnwrap(app.storage.get(ApodiniDeployInterfaceExporter.ApplicationStorageKey.self))
        let actual = apodiniDeployIE.collectedEndpoints
        
        let expected: [ApodiniDeployInterfaceExporter.CollectedEndpointInfo] = [
            ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                handlerType: HandlerTypeIdentifier(Text.self),
                endpoint: Endpoint(identifier: TestWebService.handler1Id, handler: Text("")),
                deploymentOptions: DeploymentOptions([
                    ResolvedOption(key: .memorySize, value: .mb(128)),
                    ResolvedOption(key: .timeout, value: .seconds(12))
                ])
            ),
            ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                handlerType: HandlerTypeIdentifier(Text.self),
                endpoint: Endpoint(identifier: TestWebService.handler2Id, handler: Text("")),
                deploymentOptions: DeploymentOptions([])
            ),
            ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                handlerType: HandlerTypeIdentifier(Text.self),
                endpoint: Endpoint(identifier: TestWebService.handler3Id, handler: Text("")),
                deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(70)))
            ),
            ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                handlerType: HandlerTypeIdentifier(Text.self),
                endpoint: Endpoint(identifier: TestWebService.handler4Id, handler: Text("")),
                deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(150)))
            ),
            ApodiniDeployInterfaceExporter.CollectedEndpointInfo(
                handlerType: HandlerTypeIdentifier(Text.self),
                endpoint: Endpoint(identifier: TestWebService.handler5Id, handler: Text("")),
                deploymentOptions: DeploymentOptions(ResolvedOption(key: .memorySize, value: .mb(180)))
            )
        ]
        
        let tests: [Bool] = (0..<25_000).map { actual.__compareIgnoringOrder(expected, idx: $0) }
        XCTAssertTrue(Set(tests).count == 1)
        
        
        if !actual.compareIgnoringOrder(expected) {
            let missingEndpoints = Set(expected).subtracting(actual)
            let unexpectedEndpoints = Set(actual).subtracting(expected)
            let fmtEndpointInfoSet: (Set<ApodiniDeployInterfaceExporter.CollectedEndpointInfo>) -> String = { set in
                set
                    .map { "  - HT: \($0.handlerType), id: \($0.endpoint.identifier), #opts: \($0.deploymentOptions.count)" }
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




//func ApodiniXCTAssertEqualIgnoringOrder TODO?
