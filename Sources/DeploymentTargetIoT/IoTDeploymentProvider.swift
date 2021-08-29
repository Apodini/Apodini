//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniDeployBuildSupport
import ArgumentParser
import DeviceDiscovery
import Apodini
import ApodiniUtils
import Logging
import DeploymentTargetIoTCommon


/// A deployment provider that handles the automatic deployment of a given web service to IoT devices in the network.
public class IoTDeploymentProvider: DeploymentProvider {
    /// Used to define the scope in which a `PostDiscoveryAction` is registered to the provider
    public enum RegistrationScope {
        /// The action is registered to all device types
        case all
        /// The action is registered to some device types
        case some([String])
        /// The action is registered to just one device type
        case one(String)
    }
    
    /// The identifier of the deployment provider
    public static var identifier: DeploymentProviderID {
        iotDeploymentProviderId
    }
    
    public let searchableTypes: [String]
    public let productName: String
    public let packageRootDir: URL
    public let deploymentDir: URL
    public let webServiceArguments: [String]
    
    public let automaticRedeployment: Bool
    
    // Remove later
    public let dryRun = true
    
    public var target: DeploymentProviderTarget {
        .spmTarget(packageUrl: packageRootDir, targetName: productName)
    }
    
    private var isRunning = false {
        didSet {
            isRunning ? IoTContext.startTimer() : IoTContext.endTimer()
        }
    }
    
    private var postActionMapping: [DeviceIdentifier: (DeploymentDeviceMetadata, PostDiscoveryAction.Type)] = [:]
    private let additionalConfiguration: [ConfigurationProperty: Any]
    
    internal let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    internal var results: [DiscoveryResult] = []
    
    private var packageName: String {
        packageRootDir.lastPathComponent
    }
    
    private var remotePackageRootDir: URL {
        deploymentDir.appendingPathComponent(packageName)
    }
    
    private var flattenedWebServiceArguments: String {
        webServiceArguments.joined(separator: " ")
    }
    
    /// Initializes a new `IotDeploymentProvider`
    /// - Parameter searchableTypes: An Array of devices types or their pushlished services that the provider will look for.
    /// - Parameter productName: The name of the web service's SPM target/product
    /// - Parameter packageRootDir: The directory containing the Package.swift with the to-be-deployed web service's target
    /// - Parameter deploymentDir: The remote directory the web service will be deployed/copied to
    /// - Parameter automaticRedeployment: If set, the deployment provider listens for changes in the the working directory and automatically redeploys changes to the affected nodes.
    /// - Parameter additionalConfiguration: Manually add user-defined `ConfigurationStorage` that will be accessible by the `PostDiscoveryAction`s. Defaults to [:]
    /// - Parameter webServiceArguments: If your web service has its own arguments/options, pass them here, otherwise the deployment might fail. Defaults to [].
    public init(
        searchableTypes: [String],
        productName: String,
        packageRootDir: String,
        deploymentDir: String,
        automaticRedeployment: Bool,
        additionalConfiguration: [ConfigurationProperty: Any] = [:],
        webServiceArguments: [String] = []
    ) {
        self.searchableTypes = searchableTypes
        self.productName = productName
        self.packageRootDir = URL(fileURLWithPath: packageRootDir)
        self.deploymentDir = URL(string: deploymentDir)!
        self.automaticRedeployment = automaticRedeployment
        self.additionalConfiguration = additionalConfiguration
        self.webServiceArguments = webServiceArguments
    }
    
    /// Runs the deployment
    public func run() throws {
        IoTContext.logger.notice("Starting deployment of \(productName)..")
        isRunning = true

        IoTContext.logger.info("Searching for devices in the network")
        for type in searchableTypes {
            let discovery = setup(for: type)
            
            results = try discovery.run(2).wait()
            IoTContext.logger.info("Found: \(results)")
            
            for result in results {
                IoTContext.logger.debug("Cleaning up any leftover actions data in deployment directory")
                try cleanup(on: result.device)
                
                guard
                    // do nothing if there were no post actions
                    !result.foundEndDevices.isEmpty,
                    // do nothing if all post actions returned 0
                    result.foundEndDevices.values.contains(where: { $0 != 0 })
                else {
                    IoTContext.logger.warning("No end devices were found for device \(String(describing: result.device.hostname)) or no deployment node were found")
                        continue
                    }
                IoTContext.logger.info("Starting deployment to device \(String(describing: result.device.hostname))")
                
                let device = result.device
                
                IoTContext.logger.info("Copying sources to remote")
                try copyResourcesToRemote(result)
//                try copyModelFileToRemote(result.device, localmodelFileUrl: modelFileUrl)
                
                IoTContext.logger.info("Fetching the newest dependencies")
                try fetchDependencies(on: device)
                
                IoTContext.logger.info("Building package on remote")
                try buildPackage(on: device)
                
                IoTContext.logger.info("Retrieving the system structure")
                let (modelFileUrl, deployedSystem) = try retrieveDeployedSystem(result: result, postActions: discovery.actions)
                IoTContext.logger.notice("System structure written to '\(modelFileUrl)'")
                
                // Check if we have a suitable deployment node.
                // If theres none for this device, there's no point to continue
                guard let deploymentNode = try self.deploymentNode(for: result, deployedSystem: deployedSystem)
                    else {
                        IoTContext.logger.warning("Couldn't find a deployment node for \(String(describing: result.device.hostname))")
                        continue
                    }

                // Run web service on deployed node
                IoTContext.logger.info("Starting web service on remote node!")
                try run(on: deploymentNode, device: device, modelFileUrl: modelFileUrl)
                
                IoTContext.logger.notice("Finished deployment for \(String(describing: result.device.hostname)) containing \(deploymentNode.id)")
                
                //maybe some clean up?
            }
            IoTContext.logger.notice("Completed deployment for all devices of type \(type)")
        }
        isRunning = false
    }
    
    /// Register a `PostDiscoveryAction` with a `DeploymentDeviceMetadata` to the deployment provider.
    /// - Parameter scope: The `RegistrationScope` of the action.
    /// - Parameter action: The `PostDiscoveryAction`
    /// - Parameter option: The corresponding option that will be associated with the action
    public func registerAction(
        scope: RegistrationScope,
        action: PostDiscoveryAction.Type,
        option: DeploymentDeviceMetadata
    ) {
        switch scope {
        case .all:
            self.searchableTypes.forEach { postActionMapping[DeviceIdentifier($0)] = (option, action) }
        case .some(let array):
            array.forEach { postActionMapping[DeviceIdentifier($0)] = (option, action) }
        case .one(let type):
            postActionMapping[DeviceIdentifier(type)] = (option, action)
        }
    }
    
    internal func setup(for type: String) -> DeviceDiscovery {
        let (username, password): (String, String)
        if dryRun {
            username = IoTContext.defaultUsername
            password = IoTContext.defaultPassword
        } else {
            (username, password) = IoTContext.readUsernameAndPassword(type)
        }
        
        let discovery = DeviceDiscovery(DeviceIdentifier(type), domain: .local)
        discovery.actions = [CreateDeploymentDirectoryAction.self] + postActionMapping.filter { $0.key.rawValue == type }.compactMap { $1.1 }
        
        let config: [ConfigurationProperty: Any] = [
            .username: username,
            .password: password,
            .runPostActions: true,
            IoTContext.deploymentDirectory: self.deploymentDir
        ] + additionalConfiguration
        discovery.configuration = .init(from: config)
        
        return discovery
    }
    
    private func run(on node: DeployedSystemNode, device: Device, modelFileUrl: URL) throws {
        let handlerIds: String = node.exportedEndpoints.compactMap { $0.handlerId.rawValue }.joined(separator: ",")
        let buildUrl = remotePackageRootDir
            .appendingPathComponent(".build")
            .appendingPathComponent("debug")
        let tmuxName = productName
        IoTContext.logger.debug("tmux new-session -d -s \(tmuxName) './\(productName) \(flattenedWebServiceArguments) deploy startup iot \(modelFileUrl.path) --node-id \(node.id) --endpoint-ids \(handlerIds)'")
        
        try IoTContext.runTaskOnRemote(
            "tmux new-session -d -s \(tmuxName) './\(productName) \(flattenedWebServiceArguments) deploy startup iot \(modelFileUrl.path) --node-id \(node.id) --endpoint-ids \(handlerIds)'",
            workingDir: buildUrl.path,
            device: device
        )
    }
    
    private func copyModelFileToRemote(_ device: Device, localmodelFileUrl: URL) throws {
        try IoTContext.copyResources(
            device,
            origin: localmodelFileUrl.path,
            destination: IoTContext.rsyncHostname(device, path: deploymentDir.path)
        )
    }
    
    private func retrieveDeployedSystemOnLocalMachine(
        for results: [DiscoveryResult],
        postDiscoveryActions: [PostDiscoveryAction.Type],
        executableUrl: URL
    ) throws -> (URL, DeployedSystem) {
        var infos: String = ""
        
        for result in results {
            let ipAddress = try IoTContext.ipAddress(for: result.device)
            let info = ipAddress
                .appending("-")
                .appending(postActionMapping.values
                            .compactMap { $0.0.getOptionRawValue() }
                            .joined(separator: "-")
                )
                .appending("#")
            infos.append(contentsOf: info)
        }
        
        return try self.retrieveSystemStructure(
            executableUrl,
            providerCommand: "iot",
            additionalCommands:
                [
                    "--info",
                    infos
                ],
            as: DeployedSystem.self
        )
    }
    
    // Since we dont want to compile the package locally just to retrieve the structure, we retrieve the structure remotely on every device the service is deployed on. On the devices, we compile the package anyway, so just use this.
    // We could do it just once and copy the file around, but for now this should be fine
    private func retrieveDeployedSystem(result: DiscoveryResult, postActions: [PostDiscoveryAction.Type]) throws -> (URL, DeployedSystem) {
        let modelFileName = "AM_\(UUID().uuidString).json"
        let remoteFilePath = deploymentDir.appendingPathComponent(modelFileName, isDirectory: false)
        let device = result.device
        
        let buildUrl = remotePackageRootDir
            .appendingPathComponent(".build")
            .appendingPathComponent("debug")
        
        let actionKeys = postActionMapping
            .filter { $0.key == device.identifier }
            .values
            .compactMap { $0.0.getOptionRawValue() }
            .joined(separator: "-")
        let ipAddress = try IoTContext.ipAddress(for: device)
        try IoTContext.runTaskOnRemote(
            "./\(productName) \(flattenedWebServiceArguments) deploy export-ws-structure iot \(remoteFilePath) --ip-address \(ipAddress) --action-keys \(actionKeys)",
            workingDir: buildUrl.path,
            device: device
        )
        // Since we are on remote, we need to decode the file differently.
        // Check if there are better solutions
        var responseString = ""
        try IoTContext.runTaskOnRemote(
            "cat \(remoteFilePath)",
            workingDir: self.deploymentDir.path,
            device: device,
            responseHandler: { response in
                responseString = response
            }
        )
        
        let responseData = responseString.data(using: .utf8)!
        let deployedSystem = try JSONDecoder().decode(DeployedSystem.self, from: responseData)
        
        return (remoteFilePath, deployedSystem)
    }
    
    private func copyResourcesToRemote(_ result: DiscoveryResult) throws {
        // we dont need any existing build files because we are moving to a different aarch
        let fileManager = FileManager.default
        if fileManager.directoryExists(atUrl: packageRootDir.appendingPathComponent(".build")) {
            try fileManager.removeItem(at: packageRootDir.appendingPathComponent(".build"))
        }
        try IoTContext.copyResources(
            result.device,
            origin: packageRootDir.path,
            destination: IoTContext.rsyncHostname(result.device, path: self.deploymentDir.path))
    }
    
    private func fetchDependencies(on device: Device) throws {
        try IoTContext.runTaskOnRemote(
            "swift package update",
            workingDir: self.deploymentDir.appendingPathComponent(packageName).path,
            device: device
        )
    }
    
    private func buildPackage(on device: Device) throws {
        try IoTContext.runTaskOnRemote(
            "swift build -c debug --product \(self.productName)",
            workingDir: self.deploymentDir.appendingPathComponent(packageName).path,
            device: device
        )
    }
    
    private func cleanup(on device: Device) throws {
        try IoTContext.runTaskOnRemote(
            "sudo rm -rfv !(\"\(packageName)\")",
            workingDir: self.deploymentDir.path,
            device: device,
            assertSuccess: false
        )
    }
    
    private func deploymentNode(for result: DiscoveryResult, deployedSystem: DeployedSystem) throws -> DeployedSystemNode? {
        let ipAddress = try IoTContext.ipAddress(for: result.device)
        let nodes = deployedSystem.nodes.filter { $0.id == ipAddress }
        // Since the node's id is the ip address, there should only be one deploymentnode per device.
        assert(nodes.count == 1, "There should only be one deployment node per end device")
        
        return nodes.first
    }
}

private extension Array where Element == DiscoveryResult {
    func filterPositiveResults() -> [Element] {
        filter { element in
            element.foundEndDevices.contains(where: { _, value in
                value > 0
            })
        }
    }
}

extension DeploymentDeviceMetadata {
    func getOptionRawValue() -> String? {
        self.value.option(for: .deploymentDevice)?.rawValue
    }
}
