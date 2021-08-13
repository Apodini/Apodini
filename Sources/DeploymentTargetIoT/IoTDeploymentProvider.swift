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

@main
struct IoTDeploymentCLI: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "IoT Apodini deployment provider",
            discussion: """
            Deploys an Apodini web service to devices in the local network, mapping the deployed system's nodes to independent processes.
            """,
            version: "0.0.1"
        )
    }
    
    @Option(help: "The path to the configuration file that contains infos to the searchable types, such as usernames and passwords")
    var configurationFilePath: String = ""

    @Option(help: "The type ids that should be searched for")
    var types: [String] = ["_workstation._tcp."]

    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    var inputPackageDir: String = "/Users/felice/Documents/ApodiniDemoWebService"

    @Option(help: "Name of the web service's SPM target/product")
    var productName: String = "TestWebService"

    @Option(help: "Remote directory of deployment")
    var deploymentDir: String = "/usr/deployment"
    
    @Flag(help: "If set, the deployment provider listens for changes in the the working directory and automatically redeploys changes to the affected nodes.")
    var automaticRedeployment = false
    
    @Flag(help:
            """
            **Only if automaticRedeployment is activated** - Can be set to override the current deployment when a new change occurs
            """
    )
    var overrideDeployment = false

    mutating func run() throws {
        var provider = IoTDeploymentProvider(
            searchableTypes: types,
            productName: productName,
            packageRootDir: URL(fileURLWithPath: inputPackageDir).absoluteURL,
            deploymentDir: URL(string: deploymentDir)!,
            configurationFilePath: URL(fileURLWithPath: inputPackageDir).absoluteURL,
            automaticRedeployment: true
        )
        try provider.run()
    }
}


struct IoTDeploymentProvider: DeploymentProvider {
    
    enum DeploymentMode {
        case inital
        case re
    }
    
    static var identifier: DeploymentProviderID {
        iotDeploymentProviderId
    }
    
    let searchableTypes: [String]
    let productName: String
    let packageRootDir: URL
    let deploymentDir: URL
    let configurationFilePath: URL
    
    let automaticRedeployment: Bool
    
    // Remove later
    let dryRun: Bool = true

    var target: DeploymentProviderTarget {
        .spmTarget(packageUrl: packageRootDir, targetName: productName)
    }
    
    private var isRunning = false

    private let fileManager = FileManager.default
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    
    
    internal static let logger = Logger(label: "DeploymentTargetIoT")
    
    var logger: Logger {
        Self.logger
    }
    
    var currentDeployedSystem: DeployedSystem? = nil
    var results: [DiscoveryResult] = []
    
    
    
    
    init(
        searchableTypes: [String],
        productName: String,
        packageRootDir: URL,
        deploymentDir: URL,
        configurationFilePath: URL,
        automaticRedeployment: Bool
    ) {
        self.searchableTypes = searchableTypes
        self.productName = productName
        self.packageRootDir = packageRootDir
        self.deploymentDir = deploymentDir
        self.configurationFilePath = configurationFilePath
        self.automaticRedeployment = automaticRedeployment
    }

    mutating func run(_ mode: DeploymentMode = .inital) throws {
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
            
            let (modelFileUrl, deployedSystem) = try self.retrieveDeployedSystem(for: discovery.actions, executableUrl: executableURL)
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

                logger.info("Building package on remote")
                try buildPackage(on: device)
                
                logger.info("Retrieving system structure")
                let (modelFileUrl, deployedSystem) = try retrieveDeployedSystem(on: device, postActions: discovery.actions)

                // Check if we have a suitable deployment node
                guard let deploymentNode = self.deploymentNode(for: result, deployedSystem: deployedSystem) else {
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
    
    private mutating func setup(for type: String) -> DeviceDiscovery {
        let (username, password): (String, String)
        if dryRun {
            username = IoTUtilities.defaultUsername
            password = IoTUtilities.defaultPassword
        } else {
            (username, password) = readUsernameAndPassword(type)
        }
        
        let discovery = DeviceDiscovery(DeviceIdentifier(type), domain: .local)
        discovery.actions = [CreateDeploymentDirectoryAction.self, LIFXDeviceDiscoveryAction.self]
        discovery.configuration = [
            .username: username,
            .password: password,
            .runPostActions: true,
            IoTUtilities.resourceDirectory: IoTUtilities.resourceURL,
            IoTUtilities.deploymentDirectory: self.deploymentDir,
            IoTUtilities.logger: self.logger
        ]
        return discovery
    }
    
    private func run(on node: DeployedSystemNode, device: Device, modelFileUrl: URL) throws {
        let handlerIds: String = node.exportedEndpoints.compactMap { $0.handlerId.rawValue }.joined(separator: ",")
        try IoTUtilities.runTaskOnRemote(
            "swift run \(productName) deploy startup iot \(modelFileUrl.path) --node-id \(node.id) --handler-ids \(handlerIds)",
            workingDir: self.deploymentDir.path,
            device: device
        )
    }
    
    private func retrieveDeployedSystem(
        for postDiscoveryActions: [PostDiscoveryAction.Type],
        executableUrl: URL,
        additionalCommands: [String] = []
    ) throws -> (URL, DeployedSystem) {
        try self.retrieveSystemStructure(
            executableUrl,
            providerCommand: "iot",
            additionalCommands:
                [
                    "--device-ids",
                    postDiscoveryActions.map { $0.identifier.rawValue }.joined(separator: ",")
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
        try IoTUtilities.runTaskOnRemote(
            "swift run \(productName) deploy export-ws-structure iot \(modelFileName) --device-ids \(deviceIds))",
            workingDir: self.deploymentDir.path,
            device: device
        )
        try IoTUtilities.copyResourcesToRemote(
            device,
            origin: IoTUtilities.rsyncHostname(device, path: remoteFilePath.path),
            destination: IoTUtilities.resourceURL.path
        )
        let data = try Data(contentsOf: remoteFilePath, options: [])
        let deployedSystem = try JSONDecoder().decode(DeployedSystem.self, from: data)
        
        try FileManager.default.removeItem(at: IoTUtilities.resourceURL.appendingPathComponent(modelFileName, isDirectory: false))
        
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
        try IoTUtilities.copyResourcesToRemote(
            result.device,
            origin: packageRootDir.path,
            destination: IoTUtilities.rsyncHostname(result.device, path: self.deploymentDir.path))
    }

    private func buildPackage(on device: Device) throws {
        try IoTUtilities.runTaskOnRemote(
            "swift build -Xswiftc -Xfrontend -Xswiftc -sil-verify-none --package-path \(self.deploymentDir.path) -c debug --productName \(self.productName)",
            workingDir: self.deploymentDir.path,
            device: device
        )
    }
    
    private func cleanup(on device: Device) throws {
        try IoTUtilities.runTaskOnRemote(
            "sudo rm -drf \(self.deploymentDir.path)",
            workingDir: self.deploymentDir.path,
            device: device,
            assertSuccess: false
        )
        
    }

    private func deploymentNode(for result: DiscoveryResult, deployedSystem: DeployedSystem) -> DeployedSystemNode? {
        // This is crucial and a point of discussion. If one device has multiple end devices connected to it,
        // we only consider the type with the highest number of connections
        guard let actualEndDeviceType = result.foundEndDevices.max(by: { $0.value > $1.value })?.key else {
            return nil
        }
        let nodes = deployedSystem.nodes.filter { $0.id == actualEndDeviceType.rawValue }
        // It is possible that there are no nodes for a result
        guard !nodes.isEmpty else {
            return nil
        }
        // But if there are nodes, it should be exactly 1
        assert(nodes.count == 1, "There should only be one deployment node per end device")
        return nodes.first
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

// MARK: - Uncomment when SSHClient allows synchronous calls
//private func run(on node: DeployedSystemNode, client: SSHClient?, modelFileUrl: URL) throws {
//    let handlerIds: String = node.exportedEndpoints.compactMap { $0.handlerId.rawValue }.joined(separator: ",")
//    try client?.execute(cmd: "cd \(self.deploymentDir.path)")
//    client?.assertSuccessfulExecution(cmd: "swift run \(productName) deploy startup iot \(modelFileUrl.path) --node-id \(deploymentNode) --handler-ids \(handlerIds)")
//}

//private func buildPackage(_ client:SSHClient?) {
//    client?.assertSuccessfulExecution(cmd: "swift build -Xswiftc -Xfrontend -Xswiftc -sil-verify-none --package-path \(self.deploymentDir.path) -c debug --productName \(self.productName)")
//}
