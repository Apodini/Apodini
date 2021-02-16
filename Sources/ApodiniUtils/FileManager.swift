//
//  FileManager.swift
//
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation


extension FileManager {
    public func lk_initialize() throws {
        try createDirectory(at: lk_temporaryDirectory, withIntermediateDirectories: true, attributes: [:])
    }
    
    
    public func lk_directoryExists(atUrl url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    
    public func lk_setWorkingDirectory(to newDir: URL) throws {
        guard changeCurrentDirectoryPath(newDir.path) else {
            throw ApodiniUtilsError(message: "Unable to change working directory from \(self.currentDirectoryPath) to \(newDir.path)")
        }
    }
    
    
    public var lk_temporaryDirectory: URL {
        temporaryDirectory.appendingPathComponent("Apodini", isDirectory: true)
    }
    
    
    public func lk_getTemporaryFileUrl(fileExtension: String?) -> URL {
        var tmpfile = lk_temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        if let ext = fileExtension {
            tmpfile.appendPathExtension(ext)
        }
        return tmpfile
    }
    
    
    public func lk_copyItem(at srcUrl: URL, to dstUrl: URL) throws {
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
                throw ApodiniUtilsError(message: "Unable to set file permissins: can't get file path")
            }
            try throwIfPosixError(chmod(ptr, permissions.rawValue))
        }
    }
}
