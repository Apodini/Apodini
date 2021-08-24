//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 13/08/2021.
//

import Foundation
import ApodiniDeployBuildSupport
import Apodini
import DeploymentTargetIoTCommon

extension DeploymentDevice {
    public static var lifx: Self {
        DeploymentDevice(rawValue: "lifx")
    }
}
