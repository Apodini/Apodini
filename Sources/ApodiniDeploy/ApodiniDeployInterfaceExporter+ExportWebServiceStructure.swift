//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniUtils
import ApodiniOpenAPI
import ApodiniDeployRuntimeSupport
import ApodiniDeployBuildSupport
@_implementationOnly import Vapor
import OpenAPIKit


extension ApodiniDeployInterfaceExporter {
    func exportWebServiceStructure(to outputUrl: URL, apodiniDeployConfiguration: ApodiniDeploy.ExporterConfiguration) throws {
        let deploymentConfig = apodiniDeployConfiguration.config
        guard let openApiDocument = app.storage.get(OpenAPI.StorageKey.self)?.document else {
            throw ApodiniDeployError(message: "Unable to get OpenAPI document")
        }
        var allDeploymentGroups: Set<DeploymentGroup> = deploymentConfig.deploymentGroups
        allDeploymentGroups += explicitlyCreatedDeploymentGroups.map { groupId, handlerIds in
            DeploymentGroup(id: groupId, handlerTypes: [], handlerIds: handlerIds)
        }
        let webServiceStructure = WebServiceStructure(
            endpoints: Set(collectedEndpoints.map { endpointInfo -> ExportedEndpoint in
                let endpoint = endpointInfo.endpoint
                return ExportedEndpoint(
                    handlerType: endpointInfo.handlerType,
                    handlerId: endpoint[AnyHandlerIdentifier.self],
                    deploymentOptions: endpointInfo.deploymentOptions,
                    userInfo: [:]
                )
            }),
            deploymentConfig: DeploymentConfig(
                defaultGrouping: deploymentConfig.defaultGrouping,
                deploymentGroups: allDeploymentGroups
            ),
            openApiDocument: openApiDocument,
            enabledDeploymentProviders: apodiniDeployConfiguration.runtimes.map { $0.identifier }
        )
        try webServiceStructure.writeJSON(
            to: outputUrl,
            encoderOutputFormatting: [.prettyPrinted, .withoutEscapingSlashes]
        )
    }
    
    func exportDeployedSystemIfNeeded() throws {
        guard let structureExporter = app.storage[DeploymentStructureExporterStorageKey.self] else {
            return
        }
        var allDeploymentGroups: Set<DeploymentGroup> = self.exporterConfiguration.config.deploymentGroups
        allDeploymentGroups += explicitlyCreatedDeploymentGroups.map { groupId, handlerIds in
            DeploymentGroup(id: groupId, handlerTypes: [], handlerIds: handlerIds)
        }
        let config = DeploymentConfig(defaultGrouping: self.exporterConfiguration.config.defaultGrouping, deploymentGroups: allDeploymentGroups)
        
        let deployedSystem = try structureExporter.retrieveStructure(Set(self.collectedEndpoints), config: config, app: self.app)
        print(structureExporter.fileUrl)
        try deployedSystem.writeJSON(
            to: structureExporter.fileUrl,
            encoderOutputFormatting: [.prettyPrinted, .withoutEscapingSlashes]
        )
        exit(EXIT_SUCCESS)
    }
}
