//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation


enum InternalDeployError: Error {
    case other(String)
}


public extension FileManager {
    func lk_initialize() throws {
        try createDirectory(at: lk_temporaryDirectory, withIntermediateDirectories: true, attributes: [:])
    }
    
    
    func lk_directoryExists(atUrl url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    
    func lk_setWorkingDirectory(to newDir: URL) throws {
        print("\(#function) oldCWD: \(self.currentDirectoryPath) newCWD: \(newDir.path) OR \(newDir.absoluteURL.path)")
        guard changeCurrentDirectoryPath(newDir.path) else {
            throw InternalDeployError.other("Unable to change working directory from \(self.currentDirectoryPath) to \(newDir.path)")
        }
    }
    
    
    var lk_temporaryDirectory: URL {
        temporaryDirectory.appendingPathComponent("Apodini", isDirectory: true)
    }
    
    
    func lk_getTemporaryFileUrl(fileExtension: String?) -> URL {
        var tmpfile = lk_temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        if let ext = fileExtension {
            tmpfile.appendPathExtension(ext)
        }
        return tmpfile
    }
    
    
    func lk_copyItem(at srcUrl: URL, to dstUrl: URL) throws {
        // TODO look into the -replace API
        if fileExists(atPath: dstUrl.path) {
            try removeItem(at: dstUrl)
        }
        try copyItem(at: srcUrl, to: dstUrl)
    }
}


// MARK: FileManager + POSIX Permissions

extension FileManager {
    /// Read file permissions
    public func lk_posixPermissions(ofItemAt url: URL) throws -> POSIXPermissions {
        if let value = try self.attributesOfItem(atPath: url.absoluteURL.path)[.posixPermissions] as? NSNumber {
            return POSIXPermissions(numericCast(value.uintValue))
        } else {
            throw NSError(domain: "ApodiniDeploy", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unable to read permissions for file at '\(url.absoluteURL.path)'"
            ])
        }
    }
    
    /// Write file permissions
    public func lk_setPosixPermissions(_ permissions: POSIXPermissions, forItemAt url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { ptr in
            guard let ptr = ptr else {
                throw ApodiniDeploySupportError(message: "Unable to set file permissins: can't get file path")
            }
            try throwIfPosixError(chmod(ptr, permissions.rawValue))
        }
    }
}




extension FixedWidthInteger {
    private func assertIsValidIndex(_ idx: Int) {
        precondition(
            idx >= 0 && idx < Self.bitWidth,
            "\(idx) is not a valid index for type '\(Self.self)' with bit width \(Self.bitWidth)"
        )
    }
    
    private func assertIsValidRange(_ range: Range<Int>) {
        assertIsValidIndex(range.lowerBound)
        assertIsValidIndex(range.upperBound)
    }
    
    
    public subscript(lk_bitAt idx: Int) -> Bool {
        get {
            assertIsValidIndex(idx)
            return (self & (1 << idx)) != 0
        }
        mutating set {
            if newValue {
                self |= 1 << idx
            } else {
                self &= ~(1 << idx)
            }
        }
    }

    mutating public func lk_toggleBit(at idx: Int) {
        assertIsValidIndex(idx)
        self[lk_bitAt: idx].toggle()
    }

    
    mutating func lk_replaceBits(in range: Range<Int>, withEquivalentRangeIn otherBitfield: Self) {
        assertIsValidRange(range)
        for idx in range {
            self[lk_bitAt: idx] = otherBitfield[lk_bitAt: idx]
        }
//        self = (self & )
    }
    
    
    var lk_binaryString: String {
        return (0..<Self.bitWidth).reduce(into: "") { string, idx in
            string += self[lk_bitAt: idx] ? "1" : "0"
        }
    }
}






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
    
    
    public init(_ value: mode_t) { // TODO make this optional and return nil if its not a valid permission value?
        self.rawValue = value
    }
    
    public init(rawValue: mode_t) {
        self = Self(rawValue)
    }
    
    public init(stringLiteral value: StaticString) {
        self = Self("\(value)")!
    }
    
    public init(integerLiteral value: mode_t) {
        self = Self(value)
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
        
        print("OWOOOOO BITFIELD \(rawValue.lk_binaryString)", string, self.stringRepresentation, Self(rawValue).stringRepresentation)
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
