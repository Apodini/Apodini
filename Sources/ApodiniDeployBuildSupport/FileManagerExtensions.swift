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
        guard changeCurrentDirectoryPath(newDir.path) else {
            throw InternalDeployError.other("Unable to change working directory")
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
}
