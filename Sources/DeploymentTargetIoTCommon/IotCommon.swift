//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniDeployBuildSupport
import ApodiniUtils

/// Identifier of the iot deployment provider.
public let iotDeploymentProviderId = DeploymentProviderID("de.desiderato.ApodiniDeploymentProvider.IoT")

/// Simple lauch info for IoT runtime
public struct IoTLaunchInfo: Codable {
    public let port: Int
    public let host: URL
}

public struct IoTDeploymentOptionsInnerNamespace: InnerNamespace {
    public typealias OuterNS = DeploymentOptionsNamespace
    public static let identifier: String = "org.apodini.deploy.iot"
}

public struct DeploymentDevice: OptionValue, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public func reduce(with other: DeploymentDevice) -> DeploymentDevice {
        print("reduce \(self) with \(other)")
        return self
    }
}

public extension OptionKey where InnerNS == IoTDeploymentOptionsInnerNamespace, Value == DeploymentDevice {
    /// The option key used to specify a deployment device option
    static let device = OptionKeyWithDefaultValue<IoTDeploymentOptionsInnerNamespace, DeploymentDevice>(
        key: "deploymentDevice",
        defaultValue: DeploymentDevice(rawValue: "")
    )
    
    static func device(_ id: String) -> OptionKey<IoTDeploymentOptionsInnerNamespace, DeploymentDevice> {
        OptionKey<IoTDeploymentOptionsInnerNamespace, DeploymentDevice>(
            key: "deploymentDevice." + id
        )
    }
}

public extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    /// An option for specifying the deployment device
    static func device(_ deploymentDevice: DeploymentDevice) -> AnyDeploymentOption {
        ResolvedOption(key: .device(deploymentDevice.rawValue), value: deploymentDevice)
    }
}

