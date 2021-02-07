//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-07.
//

import Foundation
import Apodini

@_exported import ApodiniDeployBuildSupport
@_exported import ApodiniDeployRuntimeSupport


public struct ApodiniDeployConfiguration: Apodini.Configuration {
    let runtimes: [DeploymentProviderRuntimeSupport.Type]
    let config: DeploymentConfig // TODO rename to options!?
    
    //public init() {}
    
    public init(runtimes: [DeploymentProviderRuntimeSupport.Type] = [], config: DeploymentConfig = .init()) {
        self.runtimes = runtimes
        self.config = config
    }
    
    
//    public func deploymentProviderRuntimes(_ runtimes: DeploymentProviderRuntimeSupport.Type...) -> Self {
//        // TODO prevent duplicate types? does it even matter?
//        .init(runtimes: self.runtimes + runtimes, config: self.config)
//    }
//
//    public func config(_ config: DeploymentConfig) -> Self {
//        .init(runtimes: self.runtimes, config: config) // TODO merge the confgs instead
//    }
    
    
    public func configure(_ app: Application) {
        app.storage.set(StorageKey.self, to: self)
    }
}



extension ApodiniDeployConfiguration {
    struct StorageKey: Apodini.StorageKey {
        typealias Value = ApodiniDeployConfiguration
    }

}
