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
    func exportWebServiceStructure(to outputUrl: URL, apodiniDeployConfiguration: ApodiniDeployConfiguration) throws {
        let deploymentConfig = apodiniDeployConfiguration.config
        guard let openApiDocument = app.storage.get(OpenAPIStorageKey.self)?.document else {
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
                    handlerId: endpoint.identifier,
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
}
