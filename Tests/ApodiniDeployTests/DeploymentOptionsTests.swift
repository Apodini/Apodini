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


struct TestOptionsNamespace: InnerNamespace {
    typealias OuterNS = DeploymentOptionsNamespace
    static let identifier: String = "testOptionsNS"
}


struct TestOption1: OptionValue, RawRepresentable {
    let rawValue: Int
    
    func reduce(with other: TestOption1) -> TestOption1 {
        TestOption1(rawValue: max(rawValue, other.rawValue))
    }
}


extension OptionKey where InnerNS == TestOptionsNamespace, Value == TestOption1 {
    /// The option key used to specify a memory size option
    static let testOption1 = OptionKey<TestOptionsNamespace, TestOption1>(
        key: "testOption1"
    )
}


extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    /// An option for specifying a memory requirement
    static func testOption1(_ value: TestOption1.RawValue) -> AnyDeploymentOption {
        ResolvedOption(key: .testOption1, value: TestOption1(rawValue: value))
    }
}


protocol ComposableOptionImpl {
    associatedtype Value: Codable
    static func reduce(lhs: Value, rhs: Value) -> Value
}


struct ComposableOption<Impl: ComposableOptionImpl>: OptionValue, RawRepresentable {
    let rawValue: Impl.Value
    
    init(rawValue: Impl.Value) {
        self.rawValue = rawValue
    }
    
    func reduce(with other: ComposableOption<Impl>) -> ComposableOption<Impl> {
        .init(rawValue: Impl.reduce(lhs: self.rawValue, rhs: other.rawValue))
    }
}


private struct TestWebService: Apodini.WebService {
    static let handler1Id = AnyHandlerIdentifier("handler1")
    static let handler2Id = AnyHandlerIdentifier("handler2")
    static let handler3Id = AnyHandlerIdentifier("handler3")
    static let handler4Id = AnyHandlerIdentifier("handler4")
    
    var content: some Component {
        Text("")
            .identified(by: Self.handler1Id)
            .deploymentOptions(.testOption1(12))
        Group("api") {
            Text("")
                .identified(by: Self.handler2Id)
                .operation(.create)
                .deploymentOptions(.testOption1(12))
            Text("")
                .identified(by: Self.handler3Id)
                .operation(.read)
                .deploymentOptions(.testOption1(15))
                .deploymentOptions(.testOption1(16))
            Text("")
                .identified(by: Self.handler4Id)
                .operation(.update)
                .deploymentOptions(.testOption1(15))
                .deploymentOptions(.testOption1(16), .testOption1(17))
        }.formDeploymentGroup(options: [
            .testOption1(14)
        ])
    }
    
    var configuration: Configuration {
        ApodiniDeploy(runtimes: [],
                      config: DeploymentConfig(defaultGrouping: .singleNode, deploymentGroups: [
                        .allHandlers(ofType: Text.self)
                      ]))
    }
}


class DeploymentOptionsTests: XCTApodiniTest {
    func testOptionMerging() throws {
        struct CapturedImplArgs: Hashable {
            let lhs, rhs: Int
        }
        struct MinOptionImpl: ComposableOptionImpl {
            private(set) static var invocationsArgs: [CapturedImplArgs] = []
            
            static func reduce(lhs: Int, rhs: Int) -> Int {
                invocationsArgs.append(.init(lhs: lhs, rhs: rhs))
                return min(lhs, rhs)
            }
        }
        
        struct MaxOptionImpl: ComposableOptionImpl {
            private(set) static var invocationsArgs: [CapturedImplArgs] = []
            
            static func reduce(lhs: Int, rhs: Int) -> Int {
                invocationsArgs.append(.init(lhs: lhs, rhs: rhs))
                return max(lhs, rhs)
            }
        }
        
        struct SumOptionImpl: ComposableOptionImpl {
            private(set) static var invocationsArgs: [CapturedImplArgs] = []
            
            static func reduce(lhs: Int, rhs: Int) -> Int {
                invocationsArgs.append(.init(lhs: lhs, rhs: rhs))
                return lhs + rhs
            }
        }
        
        typealias MinOption = ComposableOption<MinOptionImpl>
        typealias MaxOption = ComposableOption<MaxOptionImpl>
        typealias SumOption = ComposableOption<SumOptionImpl>
        
        let minOptionKey = OptionKey<TestOptionsNamespace, MinOption>(key: "min")
        let maxOptionKey = OptionKey<TestOptionsNamespace, MaxOption>(key: "max")
        let sumOptionKey = OptionKey<TestOptionsNamespace, SumOption>(key: "sum")
        
        let options: [ResolvedOption<DeploymentOptionsNamespace>] = [
            ResolvedOption(key: minOptionKey, value: MinOption(rawValue: 0)),
            ResolvedOption(key: minOptionKey, value: MinOption(rawValue: 1)),
            ResolvedOption(key: minOptionKey, value: MinOption(rawValue: 2)),
            
            ResolvedOption(key: maxOptionKey, value: MaxOption(rawValue: 3)),
            ResolvedOption(key: maxOptionKey, value: MaxOption(rawValue: 4)),
            ResolvedOption(key: maxOptionKey, value: MaxOption(rawValue: 5)),
            
            ResolvedOption(key: sumOptionKey, value: SumOption(rawValue: 6)),
            ResolvedOption(key: sumOptionKey, value: SumOption(rawValue: 7)),
            ResolvedOption(key: sumOptionKey, value: SumOption(rawValue: 8))
        ]
        
        let reducedOptions = CollectedOptions(reducing: options)
        XCTAssertEqual(3, reducedOptions.count)
        
        XCTAssertEqual(MinOptionImpl.invocationsArgs, [
            .init(lhs: 0, rhs: 1), .init(lhs: 0, rhs: 2)
        ])
        
        XCTAssertEqual(MaxOptionImpl.invocationsArgs, [
            .init(lhs: 3, rhs: 4), .init(lhs: 4, rhs: 5)
        ])
        
        XCTAssertEqual(SumOptionImpl.invocationsArgs, [
            .init(lhs: 6, rhs: 7), .init(lhs: 13, rhs: 8)
        ])
        
        let minValue = try XCTUnwrap(reducedOptions.getValue(forKey: minOptionKey))
        XCTAssertEqual(0, minValue.rawValue)
        
        let maxValue = try XCTUnwrap(reducedOptions.getValue(forKey: maxOptionKey))
        XCTAssertEqual(5, maxValue.rawValue)
        
        let sumValue = try XCTUnwrap(reducedOptions.getValue(forKey: sumOptionKey))
        XCTAssertEqual(21, sumValue.rawValue)
    }

    
    func testHandlerDeploymentOptions() throws {
        TestWebService.start(app: app)
        
        let apodiniDeployIE = try XCTUnwrap(app.storage.get(ApodiniDeployInterfaceExporter.ApplicationStorageKey.self))
        
        do {
            let handler1 = try XCTUnwrap(apodiniDeployIE.getCollectedEndpointInfo(forHandlerWithIdentifier: TestWebService.handler1Id))
            let option = try XCTUnwrap(handler1.deploymentOptions.getValue(forKey: .testOption1))
            XCTAssertEqual(12, option.rawValue)
        }
        
        do {
            let handler2 = try XCTUnwrap(apodiniDeployIE.getCollectedEndpointInfo(forHandlerWithIdentifier: TestWebService.handler2Id))
            let option = try XCTUnwrap(handler2.deploymentOptions.getValue(forKey: .testOption1))
            XCTAssertEqual(14, option.rawValue)
        }
    }
    
    
    func testHandlerDeploymentOptionComparison() {
        guard !Self.isRunningOnLinuxDebug() else {
            return
        }
        // There used to be a bug where the comparison between CollectedEndpointInfo objects would randomly fail,
        // because somehwere in the `.reduced().options.compareIgnoringOrder`
        // it compared two arrays (which are ordered collections) which were constructed from
        // dictionaries (unordered), and therefore would sometimes result in the wrong result.
        // This test attempts to make sure this problem is fixed,
        // by simply running the comparison many times and checking that they all returned the same result
        
        let opts1 = DeploymentOptions([
            ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(125)),
            ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
        ])
        let opts2 = DeploymentOptions([
            ResolvedOption<DeploymentOptionsNamespace>(key: .memorySize, value: .mb(125)),
            ResolvedOption<DeploymentOptionsNamespace>(key: .timeout, value: .seconds(12))
        ])
        
        for _ in 0..<10_000 {
            let equal = opts1.reduced().options.compareIgnoringOrder(
                opts2.reduced().options,
                computeHash: { option, hasher in hasher.combine(option) },
                areEqual: { lhs, rhs in lhs.testEqual(rhs) }
            )
            XCTAssertTrue(equal)
        }
    }
}
