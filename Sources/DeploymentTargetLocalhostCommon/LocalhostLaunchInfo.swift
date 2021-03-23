//
//  File.swift
//
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import ApodiniDeployBuildSupport


/// Identifier of the localhost deployment provider.
public let localhostDeploymentProviderId = DeploymentProviderID("de.lukaskollmer.ApodiniDeploymentProvider.Localhost")


public struct LocalhostLaunchInfo: Codable {
    public let port: Int
    
    public init(port: Int) {
        self.port = port
    }
}
