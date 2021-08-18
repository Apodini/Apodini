//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 13/08/2021.
//

import Foundation
import DeploymentTargetIoT
import ArgumentParser
import LifxDiscoveryActions
import LifxIoTDeploymentOption
import DeploymentTargetIoTCommon

@main
struct LifxDeployer: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "Deployment executor for Lifx",
            discussion: """
            A CLI to execute the IoT deployment provider for Lifx smart lamps
            """,
            version: "0.0.1"
        )
    }
    
    @OptionGroup
    var deploymentOptions: IoTDeploymentOptions

    func run() throws {
        var provider = IoTDeploymentProvider(
            searchableTypes: deploymentOptions.types,
            productName: deploymentOptions.productName,
            packageRootDir: deploymentOptions.inputPackageDir,
            deploymentDir: deploymentOptions.deploymentDir,
            configurationFilePath: deploymentOptions.configurationFilePath,
            automaticRedeployment: deploymentOptions.automaticRedeployment,
            additionalConfiguration: [
                .deploymentDirectory: deploymentOptions.deploymentDir
            ]
        )
        provider.registerAction(scope: .all, action: LIFXDeviceDiscoveryAction.self, option: .device(.lifx))
        try provider.run()
    }
}
