//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniDeployRuntimeSupport
import ArgumentParser


public struct LocalhostStartupCommand<Service: WebService>: DeploymentStartupCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "local",
            abstract: "Start a web service - Localhost",
            discussion: "Starts up an Apodini web service for the localhost deployment",
            version: "0.3.0"
        )
    }
    
    @Argument(help: "The location of the json containing the system structure")
    public var filePath: String
    
    @Option(help: "The identifier of the deployment node")
    public var nodeId: String
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try Service.start(app: app, webService: Service())
    }
    
    public init() {}
}
