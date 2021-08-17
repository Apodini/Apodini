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
        CommandConfiguration(commandName: "iot",
                             abstract: "Export web service structure - IoT",
                             discussion: """
                                    Exports an Apodini web service structure for the IoT deployment
                                  """,
                             version: "0.0.1")
    }
    
    @Option
    public var deviceIds: String
    
    @Argument(help: "The location of the json file")
    public var filePath: String = "service-structure.json"
    
    public var identifier: String = iotDeploymentProviderId.rawValue
    
    public init() {}
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        try Service.start(mode: .startup, app: app, webService: Service())
    }
    
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> DeployedSystem {
        let deviceIds = deviceIds.split(separator: ",").map { String($0) }
        let iotDeploymentGroups = deviceIds.map { id -> DeploymentGroup in
            // find explictly declared deployment groups
            let possibleDeploymentGroups = config.deploymentGroups.filter { $0.id == id }
            let allHandlerIds = possibleDeploymentGroups.flatMap { $0.handlerIds }.toSet()
            let allHandlerTypes = possibleDeploymentGroups.flatMap { $0.handlerTypes }.toSet()
            // add all types and ids that match into one group
            let deployGroup = DeploymentGroup(id: id, handlerTypes: allHandlerTypes, handlerIds: allHandlerIds)
            return deployGroup
        }
        var endpointsByDeploymentGroup = [DeploymentGroup: Set<CollectedEndpointInfo>](
            uniqueKeysWithValues: iotDeploymentGroups.map { ($0, []) }
        )
        
        for endpoint in endpoints {
            // check if an endpoint has already a matching group
            let matchingDeploymentGroups = endpointsByDeploymentGroup.keys.filter {
                $0.matches(exportedEndpointInfo: endpoint) ||
                endpoint.endpoint[AnyHandlerIdentifier.self].rawValue.contains($0.id)
            }
            
            matchingDeploymentGroups.forEach {
                endpointsByDeploymentGroup[$0]?.insert(endpoint)
            }
        }
        
        let nodes: Set<DeployedSystemNode> = try endpointsByDeploymentGroup
            .map { group, endpoints in
                try DeployedSystemNode(
                    id: group.id,
                    exportedEndpoints: endpoints.convert(),
                    userInfo: nil,
                    userInfoType: Null.self
                )
            }
            .toSet()
        return try DeployedSystem(
            deploymentProviderId: iotDeploymentProviderId,
            nodes: nodes
        )
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
    public var handlerIds: String
    
    public func run() throws {
        let app = Application()
        let handlerIds = handlerIds.split(separator: ",").map { String($0) }
        let lifeCycleHandler = IoTLifeCycleHandler(handlerIds: handlerIds)
        
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
    let handlerIds: [String]
    
    func filter(_ endpoints: [AnyEndpoint], app: Application) throws -> [AnyEndpoint] {
        endpoints.filter { handlerIds.contains($0[AnyHandlerIdentifier.self].rawValue) }
    }
}

public struct IoTDeploymentOptionsInnerNamespace: InnerNamespace {
    public typealias OuterNS = DeploymentOptionsNamespace
    public static let identifier: String = "org.apodini.deploy.iot"
}

public struct DeploymentDevice: OptionValue, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public func reduce(with other: DeploymentDevice) -> DeploymentDevice {
        print("reduce \(self) with \(other)")
        return self
    }
}

public extension OptionKey where InnerNS == IoTDeploymentOptionsInnerNamespace, Value == DeploymentDevice {
    /// The option key used to specify a deployment device option
    static let device = OptionKeyWithDefaultValue<IoTDeploymentOptionsInnerNamespace, DeploymentDevice>(
        key: "deploymentDevice",
        defaultValue: DeploymentDevice(rawValue: "")
    )
}

public extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    /// An option for specifying the deployment device
    static func device(_ deploymentDevice: DeploymentDevice) -> AnyDeploymentOption {
        ResolvedOption(key: .device, value: deploymentDevice)
    }
}
