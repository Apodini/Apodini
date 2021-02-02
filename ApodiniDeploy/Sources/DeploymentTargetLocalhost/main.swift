//
//  main.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation
import ApodiniDeployBuildSupport
import ArgumentParser
import Logging
import DeploymentTargetLocalhostCommon
#if os(Linux)
import Glibc
#else
import Darwin
#endif


// TODO rename ExportedEndpoint to ExportedEndpointInfo or smth like that!



enum DeployError: Error {
    //case unableToFindInputDirectory
    case other(String)
}



private let logger = Logger(label: "DeploymentTargetLocalhost")



private struct LocalhostDeploymentProvider: ParsableCommand, DeploymentProvider {
    static let identifier: DeploymentProviderID = LocalhostDeploymentProviderId
    static let version = 1
    
    static let configuration = CommandConfiguration(
        abstract: "Localhost Apodini deployment provider",
        discussion: """
            Deploys an Apodini web service to localhost, mapping the deployed system's nodes to independent processes
            """,
        version: String(Self.version)
    )
    
    @Argument(help: "Server package root directory")
    var inputServiceRootDirPath: String
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first child process. TODO explain more")
    var endpointProcessesBasePort: Int = 5000
    
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String // TODO make this optional?
    
    var packageRootDir: URL {
        URL(fileURLWithPath: inputServiceRootDirPath)
    }
    
    
    
    
    mutating func run() throws {
        let FM = FileManager.default
        try FM.lk_initialize()
        
        logger.notice("setting working directory to package root dir: \(packageRootDir)")
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        logger.notice("Compiling target '\(productName)'")
        let executableUrl = try buildWebService()
        logger.notice("Target executable url: \(executableUrl.path)")
        
        logger.notice("Invoking target to generate web service structure")
        let wsStructure = try generateWebServiceStructure()
        logger.notice("wsStructure: \(wsStructure)")
        
//        let nodes: [NodeLaunchInfo] = try createDefaultDeploymentStructure(from: wsStructure).enumerated().map { idx, node in
//            try NodeLaunchInfo(
//                id: node.id,
//                exportedEndpoints: node.exportedEndpoints,
//                userInfo: LocalhostLaunchInfo(port: self.endpointProcessesBasePort + idx)
//            )
//        }
        
        let nodes = try computeDefaultDeployedSystemNodes(from: wsStructure).enumerated().map { idx, node in
            try node.withUserInfo(LocalhostLaunchInfo(port: self.endpointProcessesBasePort + idx))
        }
        
        let systemConfigs: [DeployedSystemConfiguration] = try nodes.map { node in
            return try DeployedSystemConfiguration(
                deploymentProviderId: self.identifier,
                currentInstanceNodeId: node.id,
                nodes: nodes,
                userInfo: Null() // TODO we have a new thing here?
            )
        }
        
        
        let systemConfigUrls: [URL] = try systemConfigs.map { systemConfig in // alles oder nichts
            let url = FM.lk_getTemporaryFileUrl(fileExtension: "json")
            try systemConfig.writeTo(url: url)
            return url
        }
        
        for (systemConfig, systemConfigUrl) in zip(systemConfigs, systemConfigUrls) {
            //logger.notice("launching an instance for \(launchInfo)")
            let task = Task(
                executableUrl: executableUrl,
                arguments: [WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig, systemConfigUrl.path],
                captureOutput: false,
                launchInCurrentProcessGroup: true
            )
            try task.launchAsync()
            let LLI = systemConfig.currentInstanceNode.readUserInfo(as: LocalhostLaunchInfo.self)!
            //logger.notice("endpoint '\(systemConfig.currentInstanceNode.exportedEndpoints[0])' -> :\(LLI.port) @ \(task.pid)")
            logger.notice("instance w pid \(task.pid) listening at :\(LLI.port). exported endpoints: \(systemConfig.currentInstanceNode.exportedEndpoints.map(\.handlerIdRawValue))")
        }
        
        logger.notice("Starting proxy server")
        let proxyServer = try ProxyServer(
            webServiceStructure: wsStructure,
            systemConfig: systemConfigs[0] // it doesnt matter which one we use
        )
        try proxyServer.run(port: self.port)
        logger.notice("exit.")
        return
    }
}


//LocalhostDeploymentProvider.main(["/Users/lukas/Developer/Apodini/", "--product-name=TestWebService"])
LocalhostDeploymentProvider.main()
