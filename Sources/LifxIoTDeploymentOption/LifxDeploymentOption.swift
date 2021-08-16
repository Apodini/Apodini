//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 13/08/2021.
//

import Foundation
import ApodiniDeployBuildSupport
import DeploymentTargetIoTRuntime

public extension DeploymentDevice {
    static var lifx: Self {
        .init(rawValue: #function)
    }
}

//public struct Lifx: OptionValue, RawRepresentable {
//    public let rawValue: String
//
//    public init(rawValue: String = "") {
//        self.rawValue = rawValue
//    }
//
//    public func reduce(with other: Lifx) -> Lifx {
//        Lifx(rawValue: self.rawValue + other.rawValue)
//    }
//}
//
//public struct LifxInnerNamespace: InnerNamespace {
//    public typealias OuterNS = DeploymentOptionsNamespace
//    public static let identifier: String = "org.apodini.deploy.iot.lifx"
//}
//
//public extension OptionKey where InnerNS == LifxInnerNamespace, Value == Lifx {
//    /// The option key used to specify a deployment device option
//    static let lifx = OptionKeyWithDefaultValue<IoTDeploymentOptionsInnerNamespace, DeploymentDevice>(
//        key: "lifx",
//        defaultValue: Lifx()
//    )
//}
//
//public extension AnyOption where OuterNS == DeploymentOptionsNamespace {
//    /// An option for specifying the deployment device
//    static func device(_ deploymentDevice: DeploymentDevice) -> AnyDeploymentOption {
//        ResolvedOption(key: .device, value: deploymentDevice)
//    }
//}
