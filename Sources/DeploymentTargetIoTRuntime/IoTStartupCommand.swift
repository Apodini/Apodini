//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniDeployRuntimeSupport
import DeploymentTargetIoTCommon
import Apodini
import ApodiniUtils
import ArgumentParser

public struct IoTStartupCommand<Service: WebService>: DeploymentStartupCommand {
    public var deployedSystemType: AnyDeployedSystem.Type {
        DeployedSystem.self
    }
    
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "iot",
                             abstract: "Start a web service - IoT",
                             discussion: """
                                    Starts up an Apodini web service for the iot deployment
                                  """,
                             version: "0.0.1")
    }
    
    @Argument(help: "The location of the json containing the system structure")
    public var filePath: String
    
    @Option(help: "The identifier of the deployment node")
    public var nodeId: String
    
    @Option(help: "All the handler ids that should be activated")
    public var endpointIds: String
    
    public func run() throws {
        let app = Application()
        let endpointIds = endpointIds.split(separator: ",").map { String($0) }
        let lifeCycleHandler = IoTLifeCycleHandler(endpointIds: endpointIds)
        
        app.lifecycle.use(lifeCycleHandler)
        
        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try Service.start(mode: .run, app: app, webService: Service())
    }
    
    public init() {}
}

struct IoTLifeCycleHandler: LifecycleHandler {
    let endpointIds: [String]
    
    func map<IE>(
        endpoint: AnyEndpoint,
        app: Application,
        for interfaceExporter: IE
    ) throws -> [AnyEndpoint] where IE: InterfaceExporter {
        [endpoint].filter { endpointIds.contains($0[AnyHandlerIdentifier.self].rawValue) }
    }
}
