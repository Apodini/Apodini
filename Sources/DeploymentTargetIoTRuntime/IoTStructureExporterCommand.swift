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

public struct IoTStructureExporterCommand<Service: WebService>: StructureExporter {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "iot",
            abstract: "Export web service structure - IoT",
            discussion: "Exports an Apodini web service structure for the IoT deployment",
            version: "0.0.1"
        )
    }

    @Option
    public var ipAddress: String
    
    @Option
    public var actionKeys: String
    
    @Argument(help: "The location of the json file")
    public var filePath: String = "service-structure.json"
    
    @Flag
    public var docker = false
    
    public var identifier: String = iotDeploymentProviderId.rawValue
    
    public var remoteLocalhost: String {
        "0.0.0.0"
    }
    
    public init() {}
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        try Service.start(mode: .startup, app: app, webService: Service())
    }
    
    public func retrieveStructure(_ endpoints: Set<CollectedEndpointInfo>, config: DeploymentConfig, app: Application) throws -> AnyDeployedSystem {
        let actionKeys: [String] = actionKeys.split(separator: ",").map(String.init)
        var suitableEndpoints: [CollectedEndpointInfo] = []
        for endpoint in endpoints {
            // check if endpoint has a matching deployment option
            guard actionKeys.contains(where: { key in
                if let option = endpoint.deploymentOptions.option(for: .deploymentDevice) {
                    return option.rawValue.contains(key)
                }
                return false
            }) else {
                continue
            }
            suitableEndpoints.append(endpoint)
        }
        
        let node = try DeployedSystemNode(
            id: ipAddress,
            exportedEndpoints: suitableEndpoints.convert(),
            userInfo: IoTLaunchInfo(host: URL(string: docker ? remoteLocalhost : ipAddress)!, port: 8080)
        )
        return try DeployedSystem(
            deploymentProviderId: iotDeploymentProviderId,
            nodes: Set<DeployedSystemNode>([node])
        )
    }
}

private extension Array where Element: Hashable {
    func toSet() -> Set<Element> {
        Set(self)
    }
}
