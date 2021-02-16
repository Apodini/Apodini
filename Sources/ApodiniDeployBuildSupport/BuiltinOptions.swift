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


public typealias DeploymentOptions = CollectedOptions<DeploymentOptionsNamespace>
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



public struct Timeout: OptionValue, RawRepresentable {
    /// timeout in seconds
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public func reduce(with other: Timeout) -> Timeout {
        // TODO max? or min? or what?
        Timeout(rawValue: max(self.rawValue, other.rawValue))
    }
    
    
    public static func seconds(_ value: UInt) -> Timeout {
        Timeout(rawValue: value)
    }
    
    public static func minutes(_ value: UInt) -> Timeout {
        Timeout(rawValue: value * 60)
    }
}




public extension OptionKey where InnerNS == BuiltinDeploymentOptionsNamespace, Value == MemorySize {
    static let memorySize = OptionKeyWithDefaultValue<DeploymentOptionsNamespace, BuiltinDeploymentOptionsNamespace, MemorySize>(
        key: "memorySize",
        defaultValue: .mb(128)
    )
}


public extension OptionKey where InnerNS == BuiltinDeploymentOptionsNamespace, Value == Timeout {
    static let timeout = OptionKeyWithDefaultValue<DeploymentOptionsNamespace, BuiltinDeploymentOptionsNamespace, Timeout>(
        key: "timeout",
        defaultValue: .seconds(4)
    )
}


public extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    static func memory(_ memorySize: MemorySize) -> AnyOption {
        ResolvedOption(key: .memorySize, value: memorySize)
    }
    
    static func timeout(_ value: Timeout) -> AnyOption {
        ResolvedOption(key: .timeout, value: value)
    }
}
