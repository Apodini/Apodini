//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//       

import Foundation
import ArgumentParser

/// Contains all options that are required by the `IotDeploymentProvider`.
public struct IoTDeploymentOptions: ParsableArguments {
    @Option(help: "The type ids that should be searched for")
    public var types: String = "_workstation._tcp."

    @Option(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    public var inputPackageDir: String = "/Users/felice/Documents/ApodiniDemoWebService"

    @Option(help: "Name of the web service's SPM target/product")
    public var productName: String = "TestWebService"

    @Option(help: "Remote directory of deployment")
    public var deploymentDir: String = "/usr/deployment"

    @Flag(help: "If set, the deployment provider listens for changes in the working directory and automatically redeploys them."
    )
    public var automaticRedeployment = false
    
    public init() {}
}

//static let DefaultOptions = IoTDeploymentOptions(
