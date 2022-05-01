//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


extension FileManager {
    private static let didInitialize = ThreadSafeVariable<Bool>(false)
    
    /// Initialises the file manager if necessary, creating the Apodini-specific temporary directory
    private func initializeIfNecessary() throws {
        guard !Self.didInitialize.read({ $0 }) else {
            return
        }
        try Self.didInitialize.write { didInitialize in
            guard !didInitialize else {
                return
            }
            try createDirectory(at: apodiniTmpDir, withIntermediateDirectories: true, attributes: [:])
        }
    }
    
    /// Initialises the file manager, if necessary
    public func initialize() throws {
        try initializeIfNecessary()
    }
    
    /// Check whether a directory exists at `url`
    public func directoryExists(atUrl url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    
    /// Update the current working directory
    public func setWorkingDirectory(to newDir: URL) throws {
        try initializeIfNecessary()
        guard changeCurrentDirectoryPath(newDir.path) else {
            throw ApodiniUtilsError(message: "Unable to change working directory from \(self.currentDirectoryPath) to \(newDir.path)")
        }
    }
    
    /// URL of the Apodini-specific temporary directory
    public var apodiniTmpDir: URL {
        try! initializeIfNecessary()
        return temporaryDirectory.appendingPathComponent("Apodini", isDirectory: true)
    }
    
    
    /// Returns a temporary file url for the specified file extension
    public func getTemporaryFileUrl(fileExtension: String?) -> URL {
        try! initializeIfNecessary()
        var tmpfile = apodiniTmpDir
            .appendingPathComponent(UUID().uuidString)
        if let ext = fileExtension {
            tmpfile.appendPathExtension(ext)
        }
        return tmpfile
    }
    
    
    /// Copy an item at `srcUrl` to `dstUrl`, overwriting an existing item if specified
    public func copyItem(at srcUrl: URL, to dstUrl: URL, overwriteExisting: Bool) throws {
        try initializeIfNecessary()
        if overwriteExisting && fileExists(atPath: dstUrl.path) {
            try removeItem(at: dstUrl)
        }
        try copyItem(at: srcUrl, to: dstUrl)
    }
}


// MARK: FileManager + POSIX Permissions

extension FileManager {
    /// Read file permissions
    public func permissions(ofItemAt url: URL) throws -> POSIXPermissions {
        if let value = try self.attributesOfItem(atPath: url.absoluteURL.path)[.posixPermissions] as? NSNumber {
            return POSIXPermissions(rawValue: numericCast(value.uintValue))
        } else {
            throw ApodiniUtilsError(message: "Unable to read permissions for file at '\(url.absoluteURL.path)'")
        }
    }
    
    /// Write file permissions
    public func setPermissions(_ permissions: POSIXPermissions, forItemAt url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { ptr in
            guard let ptr = ptr else {
                throw ApodiniUtilsError(message: "Unable to set file permissins: can't get file path")
            }
            try throwIfPosixError(chmod(ptr, permissions.rawValue))
        }
    }
}


extension FileManager {
    /// The current platform's path separator
    public static var pathSeparator: String {
        #if os(Windows)
        return "\\"
        #else
        return "/"
        #endif
    }
}
