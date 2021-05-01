//
//  File.swift
//
//
//  Created by Lukas Kollmer on 2021-03-18.
//

// This file still is work in progress...
// swiftlint:disable all

import Foundation
import NIO
import Apodini
//import ApodiniDeployBuildSupport
import ApodiniDeploy
import DeploymentTargetLocalhostRuntime
import DeploymentTargetAWSLambdaRuntime
import ApodiniREST
import ApodiniOpenAPI




struct RandomNumberGenerator: InvocableHandler, HandlerWithDeploymentOptions {
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
        static let other = HandlerIdentifier("other")
    }
    let handlerId: HandlerIdentifier
    let ugh: Int = 12
    
    @Parameter var lowerBound: Int = 0
    @Parameter var upperBound: Int = .max
    
    func handle() throws -> Int {
        print("\(Self.self) invoked at pid \(getpid())")
        guard lowerBound <= upperBound else {
            //return 0 // TODO have this throw an error, and test how the RHI API would deal w/ that
            throw NSError(domain: "xxx", code: 123, userInfo: [NSLocalizedDescriptionKey: "localdesc"])
        }
        return Int.random(in: lowerBound...upperBound)
    }
    
    static var deploymentOptions: [AnyDeploymentOption] {
        return [
            // NOTE: starting with swift 5.4 (i believe) we'll be able to drop the leading `AnyOption` here and use the implicit member thing w/ chaining
            AnyOption.memory(.mb(150))
                .when(!(\Self.handlerId == .main || \Self.ugh == 12))
        ]
    }
}




struct Greeter: Handler {
    @Apodini.Environment(\.RHI) private var RHI
    
    @Parameter private var age: Int
    @Parameter(.http(.path)) var name: String
    
//    init(name: Parameter<String>) {
//        _name = name
//    }
    
    func handle() -> EventLoopFuture<String> {
        print("\(Self.self) invoked at pid \(getpid())")
        return RHI.invoke(
            RandomNumberGenerator.self,
            identifiedBy: .main,
            arguments: [
                .init(\.$lowerBound, age),
                .init(\.$upperBound, age * 2)
            ]
        )
        .map { randomNumber -> String in
            "Hello, \(name). Your random number in range \(age)...\(2 * age) is \(randomNumber)!"
        }
    }
}




struct BlockHandler<T: Apodini.ResponseTransformable>: Handler {
    private let block: () throws -> T
    
    init(_ block: @escaping () throws -> T) {
        self.block = block
    }
    
    func handle() throws -> T {
        try block()
    }
}


struct WebService: Apodini.WebService {
    var content: some Component {
        Group("rand") {
            RandomNumberGenerator(handlerId: .main)
        }.formDeploymentGroup(withId: "rand")
        Group("rand2") {
            RandomNumberGenerator(handlerId: .other)
        }.formDeploymentGroup(withId: "rand2")
        Group("greet") {
            Greeter()
                .deploymentOptions(
                    .memory(.mb(169)),
                    .timeout(.seconds(12))
                )
        }.formDeploymentGroup(withId: "greeter")
        BlockHandler { fatalError() }
    }
    
    var configuration: Configuration {
        ExporterConfiguration()
            .exporter(RESTInterfaceExporter.self)
            .exporter(OpenAPIInterfaceExporter.self)
            .exporter(ApodiniDeployInterfaceExporter.self)
        ApodiniDeployConfiguration(
            runtimes: [LocalhostRuntime.self, LambdaRuntime.self],
            config: DeploymentConfig(defaultGrouping: .singleNode, deploymentGroups: [])
        )
    }
}


try WebService.main()

