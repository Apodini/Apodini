//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 03/08/2021.
//

import Foundation
import ApodiniDeployRuntimeSupport
import DeploymentTargetIoTCommon
import Apodini
import ApodiniUtils
import ArgumentParser


public class IoTRuntime<Service: WebService>: DeploymentProviderRuntime {
    public static var identifier: DeploymentProviderID {
        iotDeploymentProviderId
    }
    
    public var deployedSystem: AnyDeployedSystem
    public var currentNodeId: DeployedSystemNode.ID
    private let currentNodeCustomLaunchInfo: IoTLaunchInfo
    
    public required init(deployedSystem: AnyDeployedSystem, currentNodeId: DeployedSystemNode.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        guard
            let node = deployedSystem.node(withId: currentNodeId),
            let launchInfo = node.readUserInfo(as: IoTLaunchInfo.self)
        else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to read userInfo"
            )
        }
        self.currentNodeCustomLaunchInfo = launchInfo
    }
    
    public static var exportCommand: StructureExporter.Type {
        IoTStructureExporterCommand<Service>.self
    }
    
    public static var startupCommand: DeploymentStartupCommand.Type {
        IoTStartupCommand<Service>.self
    }
    
    public func configure(_ app: Application) throws {
        app.http.address = .hostname(currentNodeCustomLaunchInfo.host.path, port: currentNodeCustomLaunchInfo.port)
    }
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        guard
            let LLI = invocation.targetNode.readUserInfo(as: IoTLaunchInfo.self),
            let url = URL(string: "\(LLI.host):\(LLI.port)")
        else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: identifier,
                message: "Unable to read port and construct url"
            )
        }
        return .invokeDefault(url: url)
    }
}

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
    public var ip: String
    
    @Option
    public var actionKeys: String
    
//    @Option
//    public var info: String
    
    @Argument(help: "The location of the json file")
    public var filePath: String = "service-structure.json"
    
    public var identifier: String = iotDeploymentProviderId.rawValue
    
    public init() {}
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        try Service.start(mode: .startup, app: app, webService: Service())
    }
    
    public func retrieveStructure(_ endpoints: Set<CollectedEndpointInfo>, config: DeploymentConfig, app: Application) throws -> AnyDeployedSystem {
        print("retrieving structure")
        let actionKeys: [String] = actionKeys.split(separator: ",").map(String.init)
        var suitableEndpoints: [CollectedEndpointInfo] = []
        for endpoint in endpoints {
            // check if endpoint has a matching deployment option
            guard !actionKeys.filter({ key in
                if let option = endpoint.deploymentOptions.option(for: .deploymentDevice) {
                    return option.rawValue.contains(key)
                }
                return false
            }).isEmpty else {
                continue
            }
            suitableEndpoints.append(endpoint)
        }
        
        let node = DeployedSystemNode(id: ip, exportedEndpoints: suitableEndpoints.convert())
        return try DeployedSystem(
            deploymentProviderId: iotDeploymentProviderId,
            nodes: Set<DeployedSystemNode>([node])
        )
        
//        var endpointsByDeviceId: [String: Set<CollectedEndpointInfo>] = [:]
//        
//        // Get device info, e.g. ipAddress-options..
//        let deviceInfos: [String] = info.split(separator: "#").map { String($0) }
//        for deviceInfo in deviceInfos {
//            let info = deviceInfo.split(separator: "-").compactMap { String($0) }
//            let ipAddress = info[0]
//            let optionKeys: [String] = Array(info.dropFirst())
//            // init empty array
//            endpointsByDeviceId[ipAddress] = []
//            
//            for endpoint in endpoints {
//                // check if endpoint has a matching deployment option
//                guard !optionKeys.filter({ key in
//                    if let option = endpoint.deploymentOptions.option(for: .deploymentDevice) {
//                        return option.rawValue.contains(key)
//                    }
//                    return false
//                }).isEmpty else {
//                    continue
//                }
//
//                endpointsByDeviceId[ipAddress]?.insert(endpoint)
//            }
//        }
//        
//        let nodes: Set<DeployedSystemNode> = try endpointsByDeviceId
//            .map { deviceId, endpoints in
//                try DeployedSystemNode(id: deviceId, exportedEndpoints: endpoints.convert())
//            }
//            .toSet()
//        
//        return try DeployedSystem(
//            deploymentProviderId: iotDeploymentProviderId,
//            nodes: nodes
//        )
    }
}

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

fileprivate extension Array where Element: Hashable {
    func toSet() -> Set<Element> {
        Set(self)
    }
}

struct IoTLifeCycleHandler: LifecycleHandler {
    let endpointIds: [String]
    
    func map<IE>(endpoint: AnyEndpoint, app: Application, for interfaceExporter: IE) throws -> [AnyEndpoint] where IE : InterfaceExporter {
        print(endpoint[AnyHandlerIdentifier.self].rawValue)
        print(endpointIds)
        return [endpoint].filter { endpointIds.contains($0[AnyHandlerIdentifier.self].rawValue) }
    }
}
