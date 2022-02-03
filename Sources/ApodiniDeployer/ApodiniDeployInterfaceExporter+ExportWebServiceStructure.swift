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
import ApodiniDeployerRuntimeSupport
import ApodiniDeployerBuildSupport

extension ApodiniDeployerInterfaceExporter {
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
        try deployedSystem.writeJSON(
            to: URL(fileURLWithPath: structureExporter.filePath),
            encoderOutputFormatting: [.prettyPrinted, .withoutEscapingSlashes]
        )
    }
}
