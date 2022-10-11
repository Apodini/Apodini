//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Logging
import Apodini
import ApodiniUtils


public struct DeploymentProviderID: RawRepresentable, Hashable, Equatable, Codable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}


/// The target on which a Deployment Provider operates.
/// Used by the default operations implemented by ApodiniDeployer.
public enum DeploymentProviderTarget {
    /// An SPM target in a package at the specified location
    case spmTarget(packageUrl: URL, targetName: String)
    
    /// An already-built executable
    case executable(URL)
}


/// A Deployment Provider, i.e. a type which can manage and facilitate the process of deploying a web service to some target platform
public protocol DeploymentProvider {
    /// This Deployment Provider's identifier. Must be unique. Use reverse DNS or something like that
    static var identifier: DeploymentProviderID { get }
    
    /// The target on which this Deployment Provider operates.
    var target: DeploymentProviderTarget { get }
    
    /// Whether ApodiniDeployer's default implementations should launch child processes in the current process group.
    /// - Note: This should be `true` in most circumstances. Only specify this as `false` if your specific deployment
    /// provider actually needs this behaviour.
    var launchChildrenInCurrentProcessGroup: Bool { get }
}


public extension DeploymentProvider {
    var identifier: DeploymentProviderID { // swiftlint:disable:this missing_docs
        Self.identifier
    }
    
    var launchChildrenInCurrentProcessGroup: Bool { true } // swiftlint:disable:this missing_docs
}


struct ApodiniDeployerBuildSupportError: Swift.Error {
    let message: String
}


extension DeploymentProvider {
    private static func getSwiftBinUrl() throws -> URL {
        if let swiftBin = ChildProcess.findExecutable(named: "swift") {
            return swiftBin
        } else {
            throw ApodiniDeployerBuildSupportError(message: "Unable to find swift compiler executable in search paths")
        }
    }
    
    
    /// Builds the web service.
    /// - Returns: the url of the built executable
    public func buildWebService() throws -> URL {
        switch target {
        case .executable(let url):
            return url
        case let .spmTarget(packageUrl, productName):
            let fileManager = FileManager()
            try fileManager.setWorkingDirectory(to: packageUrl)
            
            let swiftBin = try Self.getSwiftBinUrl()
            let task = ChildProcess(
                executableUrl: swiftBin,
                arguments: ["build", "--product", productName],
                captureOutput: false,
                launchInCurrentProcessGroup: launchChildrenInCurrentProcessGroup
            )
            guard try task.launchSync().exitCode == EXIT_SUCCESS else {
                throw ApodiniDeployerBuildSupportError(message: "Unable to build web service")
            }
            let executableUrl = packageUrl
                .appendingPathComponent(".build", isDirectory: true)
                .appendingPathComponent("debug", isDirectory: true)
                .appendingPathComponent(productName, isDirectory: false)
            guard FileManager.default.fileExists(atPath: executableUrl.path) else {
                throw ApodiniDeployerBuildSupportError(
                    message: "Unable to locate compiled executable at expected location '\(executableUrl.path)'"
                )
            }
            return executableUrl
        }
    }

    /// Retrieve a `AnyDeployedSystem` from the web service using the export-ws-structure command of the provider.
    public func retrieveSystemStructure<T: AnyDeployedSystem>(
        _ executableUrl: URL,
        providerCommand: String,
        additionalCommands: [String] = [],
        webServiceCommands: [String] = [],
        as _: T.Type = T.self) throws -> (URL, T) {
        let fileManager = FileManager()
        let logger = Logger(label: "ApodiniDeployerCLI.\(providerCommand)")
        
        let modelFileUrl = fileManager.temporaryDirectory.appendingPathComponent("AM_\(UUID().uuidString).json")
        guard fileManager.createFile(atPath: modelFileUrl.path, contents: nil, attributes: nil) else {
            throw ApodiniDeployerBuildSupportError(message: "Unable to create file")
        }
        
        let retrieveStructureTask = ChildProcess(
            executableUrl: executableUrl,
            arguments:
                webServiceCommands +
            [
                "deploy",
                "export-ws-structure",
                providerCommand,
                modelFileUrl.path
            ] + additionalCommands,
            captureOutput: false,
            launchInCurrentProcessGroup: launchChildrenInCurrentProcessGroup
        )
        let terminationInfo = try retrieveStructureTask.launchSync()
        guard terminationInfo.exitCode == EXIT_SUCCESS else {
            throw ApodiniDeployerBuildSupportError(message: "Unable to generate system structure: \(terminationInfo.exitCode)")
        }
        
        logger.notice("System structure written to '\(modelFileUrl)'")
        let data = try Data(contentsOf: modelFileUrl, options: [])
        return (modelFileUrl, try JSONDecoder().decode(T.self, from: data))
    }
}
