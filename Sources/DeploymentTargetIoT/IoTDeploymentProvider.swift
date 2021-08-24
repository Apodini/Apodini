//
//  File.swift
//
//
//  Created by Felix Desiderato on 03/08/2021.
//
import Foundation
import ApodiniDeployBuildSupport
import ArgumentParser
import DeviceDiscovery
import Apodini
import ApodiniUtils
import Logging
import DeploymentTargetIoTCommon


public class IoTDeploymentProvider: DeploymentProvider {
    public static var identifier: DeploymentProviderID {
        iotDeploymentProviderId
    }
    
    public let searchableTypes: [String]
    public let productName: String
    public let packageRootDir: URL
    public let deploymentDir: URL
    public let configurationFilePath: URL
    
    public let automaticRedeployment: Bool
    
    // Remove later
    public let dryRun: Bool = true
    
    public var target: DeploymentProviderTarget {
        .spmTarget(packageUrl: packageRootDir, targetName: productName)
    }
    
    private var isRunning = false
    
    private let fileManager = FileManager.default
    
    private var postActionMapping: [DeviceIdentifier: (DeploymentDeviceMetadata, PostDiscoveryAction.Type)] = [:]
    private let additionalConfiguration: [ConfigurationProperty: Any]
    
    internal let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    internal static let logger = Logger(label: "DeploymentTargetIoT")
    
    public var logger: Logger {
        Self.logger
    }
    
    public var currentDeployedSystem: DeployedSystem? = nil
    public var results: [DiscoveryResult] = []
    
    
    public init(
        searchableTypes: [String],
        productName: String,
        packageRootDir: String,
        deploymentDir: String,
        configurationFilePath: String,
        automaticRedeployment: Bool,
        additionalConfiguration: [ConfigurationProperty: Any] = [:]
    ) {
        self.searchableTypes = searchableTypes
        self.productName = productName
        self.packageRootDir = URL(fileURLWithPath: packageRootDir)
        self.deploymentDir = URL(string: deploymentDir)!
        self.configurationFilePath = URL(fileURLWithPath: configurationFilePath)
        self.automaticRedeployment = automaticRedeployment
        self.additionalConfiguration = additionalConfiguration
    }
    
    public enum RegistrationScope {
        case all
        case some([String])
        case one(String)
    }
    
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
    
    public func run() throws {
        try fileManager.initialize()
        try fileManager.setWorkingDirectory(to: packageRootDir)
        
        logger.notice("Starting deployment of \(productName)..")
        isRunning = true
        
        try listenForChanges()
        
        let executableURL = try buildWebService()
        
        logger.info("Search for devices in the network")
        for type in searchableTypes {
            let discovery = setup(for: type)
            
            results = try discovery.run(2).wait()
            logger.info("Found: \(results)")
            
            let (modelFileUrl, deployedSystem) = try self.retrieveDeployedSystemOnLocalMachineTmp(deviceID: type, postDiscoveryActions: discovery.actions, executableUrl: executableURL)
            
//            let (modelFileUrl, deployedSystem) = try self.retrieveDeployedSystemOnLocalMachine(
//                for: results,
//                   postDiscoveryActions: discovery.actions,
//                   executableUrl: executableURL
//            )
            
            print(modelFileUrl)
            print(deployedSystem)
            
            for result in results {
                // Clean up any previous deployment
                try cleanup(on: result.device)
                
                guard
                    // do nothing if there were no post actions
                    !result.foundEndDevices.isEmpty,
                    // do nothing if all post actions returned 0
                    result.foundEndDevices.values.contains(where: { $0 != 0 }) else {
                        logger.warning("No end devices were found for device \(result.device.hostname)")
                        continue
                    }
                logger.warning("Starting deployment to device \(result.device.hostname)")
                
                let device = result.device
                //                let sshClient = try getSSHClient(for: device, configuration: discovery.configuration)
                
                logger.info("Copying sources to remote")
                try copyResourcesToRemote(result)
                try copyModelFileToRemote(result.device, localmodelFileUrl: modelFileUrl)
                
                logger.info("Building package on remote")
                try buildPackage(on: device)
                
                //TODO: Activate later
                //                logger.info("Retrieving system structure")
                //                let (modelFileUrl, deployedSystem) = try retrieveDeployedSystem(on: device, postActions: discovery.actions)
                
                // Check if we have a suitable deployment node
                guard let deploymentNode = try self.deploymentNode(for: result, deployedSystem: deployedSystem) else {
                    logger.error("No deployment node found for device \(device.hostname)")
                    // do some cleanup here
                    continue
                }
                
                // Run web service on deployed node
                logger.info("Starting web service on remote node")
                try run(on: deploymentNode, device: device, modelFileUrl: modelFileUrl)
                
                logger.notice("Finished deployment for \(String(describing: result.device.hostname)) containing \(deploymentNode.id)")
                
                //maybe some clean up?
            }
            logger.notice("Completed deployment for all devices of type \(type)")
        }
        isRunning = false
        logger.notice("Completed deployment.")
    }
    
    internal func setup(for type: String) -> DeviceDiscovery {
        let (username, password): (String, String)
        if dryRun {
            username = IoTContext.defaultUsername
            password = IoTContext.defaultPassword
        } else {
            (username, password) = readUsernameAndPassword(type)
        }
        
        let discovery = DeviceDiscovery(DeviceIdentifier(type), domain: .local)
        discovery.actions = [CreateDeploymentDirectoryAction.self] + postActionMapping.filter { $0.key.rawValue == type }.compactMap { $1.1 }
        
        let config: [ConfigurationProperty: Any] = [
            .username: username,
            .password: password,
            .runPostActions: true,
            IoTContext.deploymentDirectory: self.deploymentDir,
            IoTContext.logger: self.logger
        ] + additionalConfiguration
        discovery.configuration = .init(from: config)
        
        return discovery
    }
    
    private func run(on node: DeployedSystemNode, device: Device, modelFileUrl: URL) throws {
        let handlerIds: String = node.exportedEndpoints.compactMap { $0.handlerId.rawValue }.joined(separator: ",")
        try IoTContext.runTaskOnRemote(
            "swift run \(productName) deploy startup iot \(modelFileUrl.path) --node-id \(node.id) --endpoint-ids \(handlerIds)",
            workingDir: self.deploymentDir.path,
            device: device
        )
    }
    
    private func copyModelFileToRemote(_ device: Device, localmodelFileUrl: URL) throws {
        try IoTContext.copyResourcesToRemote(
            device,
            origin: localmodelFileUrl.path,
            destination: IoTContext.rsyncHostname(device, path: deploymentDir.path)
        )
    }
    
    private func retrieveDeployedSystemOnLocalMachineTmp(
        deviceID: String,
        postDiscoveryActions: [PostDiscoveryAction.Type],
        executableUrl: URL) throws -> (URL, DeployedSystem) {
            var infos: String = ""
            let info = deviceID
                .appending("-")
                .appending(postActionMapping.values
                            .compactMap { $0.0.getOptionRawValue() }
                            .joined(separator: "-")
                )
                .appending("#")
            infos.append(contentsOf: info)
            
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
    
    private func retrieveDeployedSystemOnLocalMachine(
        for results: [DiscoveryResult],
        postDiscoveryActions: [PostDiscoveryAction.Type],
        executableUrl: URL
    ) throws -> (URL, DeployedSystem) {
        var infos: String = ""
        
        for result in results {
            guard let ipAddress = result.device.ipv4Address else {
                throw IoTDeploymentError(description: "Unable to initialise system retrieval - ip address not found")
            }
            let info = ipAddress
                .appending("-")
                .appending(result.foundEndDevices
                            .filter { $0.value > 0 }
                            .map { $0.key.rawValue }
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
    
    private func retrieveDeployedSystem(on device: Device, postActions: [PostDiscoveryAction.Type]) throws -> (URL, DeployedSystem) {
        //1. set file name and url
        //2. run export-ws-structure command
        //3. copy modelfile from remote to local
        //4. read data from file and parse it as deployed system
        //5. remove local file
        let modelFileName = "AM_\(UUID().uuidString).json"
        let remoteFilePath = deploymentDir.appendingPathComponent(modelFileName, isDirectory: false)
        
        let deviceIds: String = postActions.map { $0.identifier.rawValue }.joined(separator: ",")
        try IoTContext.runTaskOnRemote(
            "swift run \(productName) deploy export-ws-structure iot \(modelFileName) --device-ids \(deviceIds))",
            workingDir: self.deploymentDir.path,
            device: device
        )
        try IoTContext.copyResourcesToRemote(
            device,
            origin: IoTContext.rsyncHostname(device, path: remoteFilePath.path),
            destination: IoTContext.resourceURL.path
        )
        let data = try Data(contentsOf: remoteFilePath, options: [])
        let deployedSystem = try JSONDecoder().decode(DeployedSystem.self, from: data)
        
        try FileManager.default.removeItem(at: IoTContext.resourceURL.appendingPathComponent(modelFileName, isDirectory: false))
        
        return (remoteFilePath, deployedSystem)
    }
    
    private func getSSHClient(for device: Device, configuration: ConfigurationStorage) throws -> SSHClient? {
        guard let username = configuration.typedValue(for: .username, to: String.self),
              let password = configuration.typedValue(for: .password, to: String.self),
              let ipAddress = device.ipv4Address else {
                  return nil
              }
        
        return try SSHClient(username: username, password: password, ipAdress: ipAddress)
    }
    
    private func copyResourcesToRemote(_ result: DiscoveryResult) throws {
        // we dont need any existing build files because we moving to a different aarch
        if fileManager.directoryExists(atUrl: packageRootDir.appendingPathComponent(".build")) {
            try fileManager.removeItem(at: packageRootDir.appendingPathComponent(".build"))
        }
        try IoTContext.copyResourcesToRemote(
            result.device,
            origin: packageRootDir.path,
            destination: IoTContext.rsyncHostname(result.device, path: self.deploymentDir.path))
    }
    
    private func buildPackage(on device: Device) throws {
        try IoTContext.runTaskOnRemote(
            "swift build -Xswiftc -Xfrontend -Xswiftc -sil-verify-none --package-path \(self.deploymentDir.path) -c debug --productName \(self.productName)",
            workingDir: self.deploymentDir.path,
            device: device
        )
    }
    
    private func cleanup(on device: Device) throws {
        try IoTContext.runTaskOnRemote(
            "sudo rm -drf \(self.deploymentDir.path)",
            workingDir: self.deploymentDir.path,
            device: device,
            assertSuccess: false
        )
        
    }
    
    private func deploymentNode(for result: DiscoveryResult, deployedSystem: DeployedSystem) throws -> DeployedSystemNode? {
        guard let ipAddress = result.device.ipv4Address else {
            throw IoTDeploymentError(description: "Unable to find DeployedSystemNode - ip address was not found")
        }
        let nodes = deployedSystem.nodes.filter { $0.id == ipAddress }
        assert(nodes.count == 1, "There should only be one deployment node per end device")
        
        return nodes.first
        
//        // This is crucial and a point of discussion. If one device has multiple end devices connected to it,
//        // we only consider the type with the highest number of connections
//        guard let actualEndDeviceType = result.foundEndDevices.max(by: { $0.value > $1.value })?.key else {
//            return nil
//        }
//        let nodes = deployedSystem.nodes.filter { $0.id == actualEndDeviceType.rawValue }
//        // It is possible that there are no nodes for a result
//        guard !nodes.isEmpty else {
//            return nil
//        }
//        // But if there are nodes, it should be exactly 1
//        assert(nodes.count == 1, "There should only be one deployment node per end device")
//        return nodes.first
    }
    
    private func readUsernameAndPassword(_ type: String) -> (String, String) {
        logger.info("The username for devices of type \(type) :")
        var username = readLine()
        while username.isEmpty {
            username = readLine()
        }
        logger.info("The password for devices of type \(type) :")
        let passw = getpass("")
        return (username!, String(cString: passw!))
    }
}

public extension String {
    func asFileUrl(_ isDir: Bool = false) -> URL {
        URL(fileURLWithPath: self, isDirectory: isDir)
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


// MARK: - Uncomment when SSHClient allows synchronous calls
//private func run(on node: DeployedSystemNode, client: SSHClient?, modelFileUrl: URL) throws {
//    let handlerIds: String = node.exportedEndpoints.compactMap { $0.handlerId.rawValue }.joined(separator: ",")
//    try client?.execute(cmd: "cd \(self.deploymentDir.path)")
//    client?.assertSuccessfulExecution(cmd: "swift run \(productName) deploy startup iot \(modelFileUrl.path) --node-id \(deploymentNode) --handler-ids \(handlerIds)")
//}

//private func buildPackage(_ client:SSHClient?) {
//    client?.assertSuccessfulExecution(cmd: "swift build -Xswiftc -Xfrontend -Xswiftc -sil-verify-none --package-path \(self.deploymentDir.path) -c debug --productName \(self.productName)")
//}
