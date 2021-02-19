//
//  POSIXPermissions.swift
//
//
//  Created by Lukas Kollmer on 16.02.21.
//


import Foundation // Darwin.posix


/// POSIX File System Permissions
public struct POSIXPermissions: RawRepresentable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
    public var rawValue: mode_t = 0
    
    public var owner: PermissionValues {
        get { PermissionValues(rawValue: (self.rawValue & S_IRWXU) >> 6) }
        set {
            assert(S_IRWXU.trailingZeroBitCount == 6)
            rawValue = (rawValue & ~S_IRWXU) | (newValue.rawValue << 6)
        }
    }
    public var group: PermissionValues {
        get { PermissionValues(rawValue: (self.rawValue & S_IRWXG) >> 3) }
        set {
            assert(S_IRWXG.trailingZeroBitCount == 3)
            rawValue = (rawValue & ~S_IRWXG) | (newValue.rawValue << 3)
        }
    }
    public var world: PermissionValues {
        get { PermissionValues(rawValue: (self.rawValue & S_IRWXO) >> 0) }
        set {
            assert(S_IRWXO.trailingZeroBitCount == 0)
            rawValue = (rawValue & ~S_IRWXO) | (newValue.rawValue << 0)
        }
    }
    
    
    public init(rawValue: mode_t) {
        self.rawValue = rawValue
    }
    
    public init(integerLiteral value: mode_t) {
        self = Self(rawValue: value)
    }
    
    public init(stringLiteral value: StaticString) {
        self = Self("\(value)")!
    }
    
    
    public init(owner: PermissionValues, group: PermissionValues, world: PermissionValues) {
        self.owner = owner
        self.group = group
        self.world = world
    }
    
    
    public init?(_ string: String) {
        guard string.unicodeScalars.allSatisfy(\.isASCII) && string.count == 9 else {
            return nil
        }
        // This function returning false indicates an error while parsing
        func read_imp(into dst: inout PermissionValues, startOffset: Int) -> Bool {
            let startIdx = string.index(string.startIndex, offsetBy: startOffset)
            for char in string[startIdx..<string.index(startIdx, offsetBy: 3)] {
                switch char {
                case "r": dst.insert(.read)
                case "w": dst.insert(.write)
                case "x": dst.insert(.execute)
                case "-": break
                default: return false
                }
            }
            return true
        }
        guard read_imp(into: &owner, startOffset: 0) else {
            return nil
        }
        guard read_imp(into: &group, startOffset: 3) else {
            return nil
        }
        guard read_imp(into: &world, startOffset: 6) else {
            return nil
        }
    }
    
    
    public var stringRepresentation: String {
        var str = ""
        str.reserveCapacity(9)
        for values in [owner, group, world] {
            str.append(values.contains(.read) ? "r" : "-")
            str.append(values.contains(.write) ? "w" : "-")
            str.append(values.contains(.execute) ? "x" : "-")
        }
        return str
    }
}


extension POSIXPermissions {
    public struct PermissionValues: OptionSet {
        public let rawValue: mode_t
        
        public init(rawValue: mode_t) {
            self.rawValue = rawValue
        }

        public static let read = PermissionValues(rawValue: 1 << 2)
        public static let write = PermissionValues(rawValue: 1 << 1)
        public static let execute = PermissionValues(rawValue: 1 << 0)
    }
}
