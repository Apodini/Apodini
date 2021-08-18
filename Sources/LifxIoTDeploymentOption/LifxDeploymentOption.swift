//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 13/08/2021.
//

import Foundation
import ApodiniDeployBuildSupport
import DeploymentTargetIoTCommon

public extension DeploymentDevice {
    static var lifx: Self {
        .init(rawValue: #function)
    }
}
