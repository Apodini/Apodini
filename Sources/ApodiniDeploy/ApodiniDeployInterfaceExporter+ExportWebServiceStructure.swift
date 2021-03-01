//
//  ApodiniDeployInterfaceExporter+ExportWebServiceStructure.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation
import Apodini
import ApodiniUtils
import ApodiniOpenAPI
import ApodiniDeployBuildSupport
@_implementationOnly import Vapor
import OpenAPIKit


extension ApodiniDeployInterfaceExporter {
    func exportWebServiceStructure(to outputUrl: URL, deploymentConfig: DeploymentConfig) throws {
        guard let openApiDocument = app.storage.get(OpenAPIStorageKey.self)?.document else {
            throw ApodiniDeployError(message: "Unable to get OpenAPI document")
        }
        var allDeploymentGroups: Set<DeploymentGroup> = deploymentConfig.deploymentGroups.groups
        allDeploymentGroups += explicitlyCreatedDeploymentGroups.map { groupId, handlerIds in
            DeploymentGroup(id: groupId, handlerTypes: [], handlerIds: handlerIds)
        }
        let webServiceStructure = WebServiceStructure(
            endpoints: Set(collectedEndpoints.map { endpointInfo -> ExportedEndpoint in
                let endpoint = endpointInfo.endpoint
                return ExportedEndpoint(
                    handlerType: endpointInfo.handlerType,
                    handlerId: endpoint.identifier,
                    deploymentOptions: endpointInfo.deploymentOptions,
                    userInfo: [:]
                )
            }),
            deploymentConfig: DeploymentConfig(
                deploymentGroups: DeploymentGroupsConfig(
                    defaultGrouping: deploymentConfig.deploymentGroups.defaultGrouping,
                    groups: allDeploymentGroups
                )
            ),
            openApiDocument: openApiDocument
        )
        try webServiceStructure.writeJSON(
            to: outputUrl,
            encoderOutputFormatting: [.prettyPrinted, .withoutEscapingSlashes]
        )
    }
}
