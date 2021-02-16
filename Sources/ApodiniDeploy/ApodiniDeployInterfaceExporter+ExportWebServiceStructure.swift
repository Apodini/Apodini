//
//  ApodiniDeployInterfaceExporter+ExportWebServiceStructure.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation
import Apodini
import ApodiniUtils
@testable import ApodiniOpenAPI
import ApodiniDeployBuildSupport
@_implementationOnly import Vapor
import OpenAPIKit


// TODO: this is copied from the RESTExporter. remove once we dont propagate this to the WSS anymore!
extension Vapor.HTTPMethod {
    fileprivate init(_ operation: Apodini.Operation) {
        switch operation {
        case .create:
            self =  .POST
        case .read:
            self =  .GET
        case .update:
            self =  .PUT
        case .delete:
            self =  .DELETE
        }
    }
}


extension ApodiniDeployInterfaceExporter {
    func exportWebServiceStructure(to outputUrl: URL, deploymentConfig: DeploymentConfig) throws {
        guard let openApiDocument = app.storage.get(OpenAPIStorageKey.self)?.document else {
            throw makeApodiniError("Unable to get OpenAPI document")
        }
        let openApiDefinitionData = try JSONEncoder().encode(openApiDocument)
        let webServiceStructure = WebServiceStructure(
            endpoints: Set(collectedEndpoints.map { endpointInfo -> ExportedEndpoint in
                let endpoint = endpointInfo.endpoint
                return ExportedEndpoint(
                    handlerType: endpointInfo.handlerType,
                    handlerId: endpoint.identifier,
                    deploymentOptions: endpointInfo.deploymentOptions,
                    httpMethod: Vapor.HTTPMethod(endpoint.operation).string, // TODO remove this and load it from the OpenAPI def instead?. same for the path...
                    absolutePath: endpoint.absolutePath.asPathString(parameterEncoding: .id),
                    userInfo: [:]
                )
            }),
            deploymentConfig: DeploymentConfig(
                deploymentGroups: DeploymentGroupsConfig(
                    defaultGrouping: deploymentConfig.deploymentGroups.defaultGrouping,
                    groups: deploymentConfig.deploymentGroups.groups + explicitlyCreatedDeploymentGroups.map { groupId, handlerIds -> DeploymentGroup in
                        DeploymentGroup(id: groupId, handlerTypes: [], handlerIds: handlerIds)
                    }
                )
            ),
            openApiDefinition: openApiDefinitionData
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(webServiceStructure)
        try data.write(to: outputUrl)
    }
}
