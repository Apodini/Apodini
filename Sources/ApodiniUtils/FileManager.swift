//
//  FileManager.swift
//
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation


extension FileManager {
    /// Initialises the file manager, creating the Apodini-specific temporary directory
    public func initialize() throws {
        try createDirectory(at: apodiniDeployTmpDir, withIntermediateDirectories: true, attributes: [:])
    }
    
    /// Check whether a directory exists at `url`
    public func directoryExists(atUrl url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    
    /// Update the current working directory
    public func setWorkingDirectory(to newDir: URL) throws {
        guard changeCurrentDirectoryPath(newDir.path) else {
            throw ApodiniUtilsError(message: "Unable to change working directory from \(self.currentDirectoryPath) to \(newDir.path)")
        }
    }
    
    /// Url of the Apodini-specific temporary directory
    public var apodiniDeployTmpDir: URL {
        temporaryDirectory.appendingPathComponent("ApodiniDeploy", isDirectory: true)
    }
    
    
    /// Returns a temporary file url for the specified file extension
    public func getTemporaryFileUrl(fileExtension: String?) -> URL {
        var tmpfile = apodiniDeployTmpDir
            .appendingPathComponent(UUID().uuidString)
        if let ext = fileExtension {
            tmpfile.appendPathExtension(ext)
        }
        return tmpfile
    }
    
    
    /// Copy an item at `srcUrl` to `dstUrl`, overwriting an existing item if specified
    public func copyItem(at srcUrl: URL, to dstUrl: URL, overwriteExisting: Bool) throws {
        if overwriteExisting && fileExists(atPath: dstUrl.path) {
            try removeItem(at: dstUrl)
        }
        try copyItem(at: srcUrl, to: dstUrl)
    }
}


// MARK: FileManager + POSIX Permissions

extension FileManager {
    /// Read file permissions
    public func posixPermissions(ofItemAt url: URL) throws -> POSIXPermissions {
        if let value = try self.attributesOfItem(atPath: url.absoluteURL.path)[.posixPermissions] as? NSNumber {
            return POSIXPermissions(rawValue: numericCast(value.uintValue))
        } else {
            throw NSError(domain: "ApodiniDeploy", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unable to read permissions for file at '\(url.absoluteURL.path)'"
            ])
        }
    }
    
    /// Write file permissions
    public func setPosixPermissions(_ permissions: POSIXPermissions, forItemAt url: URL) throws {
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
