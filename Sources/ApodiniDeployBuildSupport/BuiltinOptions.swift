//
//  BuiltinOptions.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-30.
//

import Foundation


public struct MemorySize: DeploymentOption, RawRepresentable {
    public typealias RawValue = UInt
    // memory size, in MB
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    
    public static func mb(_ value: RawValue) -> Self {
        .init(rawValue: value)
    }
    
    public func reduce(with other: MemorySize) -> MemorySize {
        MemorySize(rawValue: max(self.rawValue, other.rawValue))
    }
}



public struct Timeout: DeploymentOption, RawRepresentable {
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



public final class XBuiltinOptionsNamespace: OptionNamespace {
    public static let id: String = "org.apodini"
}


public extension OptionKey where NS == XBuiltinOptionsNamespace, Value == MemorySize {
    static let memorySize = OptionKeyWithDefaultValue<XBuiltinOptionsNamespace, MemorySize>(
        key: "memorySize",
        defaultValue: .mb(128)
    )
}


public extension OptionKey where NS == XBuiltinOptionsNamespace, Value == Timeout {
    static let timeout = OptionKeyWithDefaultValue<XBuiltinOptionsNamespace, Timeout>(
        key: "timeout",
        defaultValue: .seconds(4)
    )
}


public extension AnyDeploymentOption {
    static func memory(_ memorySize: MemorySize) -> AnyDeploymentOption {
        ResolvedDeploymentOption(key: .memorySize, value: memorySize)
    }
    
    static func timeout(_ value: Timeout) -> AnyDeploymentOption {
        ResolvedDeploymentOption(key: .timeout, value: value)
    }
}




extension Set {
    mutating func lk_insert(_ newElement: Element, merging mergingFn: (_ oldElem: Element, _ newElem: Element) -> Element) {
        if let idx = firstIndex(of: newElement) {
            insert(mergingFn(self[idx], newElement))
        } else {
            insert(newElement)
        }
    }
}
