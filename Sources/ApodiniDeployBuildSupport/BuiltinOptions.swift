//
//  BuiltinOptions.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-30.
//

import Foundation


public final class DeploymentOptionsNamespace: OuterNamespace {
    public static let id: String = "DeploymentOptions"
}


/// A list of deployment options
public typealias DeploymentOptions = CollectedOptions<DeploymentOptionsNamespace>
/// An untyped deployment option
public typealias AnyDeploymentOption = AnyOption<DeploymentOptionsNamespace>


public final class BuiltinDeploymentOptionsNamespace: InnerNamespace {
    public typealias OuterNS = DeploymentOptionsNamespace
    public static let id: String = "org.apodini"
}


public struct MemorySize: OptionValue, RawRepresentable {
    /// memory size, in MB
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static func mb(_ value: UInt) -> Self {
        .init(rawValue: value)
    }
    
    public func reduce(with other: MemorySize) -> MemorySize {
        MemorySize(rawValue: max(self.rawValue, other.rawValue))
    }
}


/// The `TimeoutValue` struct can be used as an option's value, and represents a time interval in seconds
public struct TimeoutValue: OptionValue, RawRepresentable {
    /// timeout in seconds
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public func reduce(with other: TimeoutValue) -> TimeoutValue {
        TimeoutValue(rawValue: max(self.rawValue, other.rawValue))
    }
    
    
    public static func seconds(_ value: UInt) -> TimeoutValue {
        TimeoutValue(rawValue: value)
    }
    
    public static func minutes(_ value: UInt) -> TimeoutValue {
        TimeoutValue(rawValue: value * 60)
    }
}


public extension OptionKey where InnerNS == BuiltinDeploymentOptionsNamespace, Value == MemorySize {
    /// The option key used to specify a memory size option
    static let memorySize = OptionKeyWithDefaultValue<BuiltinDeploymentOptionsNamespace, MemorySize>(
        key: "memorySize",
        defaultValue: .mb(128)
    )
}


public extension OptionKey where InnerNS == BuiltinDeploymentOptionsNamespace, Value == TimeoutValue {
    /// The option key used to specify a timeout option
    static let timeout = OptionKeyWithDefaultValue<BuiltinDeploymentOptionsNamespace, TimeoutValue>(
        key: "timeout",
        defaultValue: .seconds(4)
    )
}


extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    /// An option for specifying a memory requirement
    public static func memory(_ memorySize: MemorySize) -> AnyDeploymentOption {
        ResolvedOption(key: .memorySize, value: memorySize)
    }
    
    /// An option for specifying a timeout requirement
    public static func timeout(_ value: TimeoutValue) -> AnyDeploymentOption {
        ResolvedOption(key: .timeout, value: value)
    }
}
