//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif
import Foundation
import Logging
import ApodiniUtils


/// `Directory` represents a specified directory.
/// It can also be used to derive a working directory automatically.
public struct Directory {
    /// Path to the current working directory.
    public var workingDirectory: String
    /// Path to the current resource directory.
    public var resourcesDirectory: String
    /// Path to the current public directory.
    public var publicDirectory: String
    
    /// Create a new `Directory` with a custom working directory.
    ///
    /// - parameters:
    ///     - workingDirectory: Custom working directory path.
    public init(workingDirectory: String) {
        self.workingDirectory = workingDirectory.withSuffix("/")
        self.resourcesDirectory = self.workingDirectory + "Resources/"
        self.publicDirectory = self.workingDirectory + "Public/"
    }
    
    /// Creates a `Directory` by deriving a working directory using the `#file` variable or `getcwd` method.
    ///
    /// - returns: The derived `Directory` if it could be created, otherwise just "./".
    public static func detect() -> Directory {
        let logger = Logger(label: "org.apodini.application")
        
        // get actual working directory
        let cwd = getcwd(nil, Int(PATH_MAX))
        defer {
            free(cwd)
        }

        let workingDirectory: String

        if let cwd = cwd, let string = String(validatingUTF8: cwd) {
            workingDirectory = string
        } else {
            workingDirectory = "./"
        }

        #if Xcode
        if workingDirectory.contains("DerivedData") {
            logger.warning("No custom working directory set for this scheme")
            logger.warning("Setting dummy directory for debug purposes")
            do {
                if !FileManager.default.fileExists(atPath: workingDirectory + "/Public/") {
                    try FileManager.default.createDirectory(
                        atPath: workingDirectory + "/Public/",
                        withIntermediateDirectories: false,
                        attributes: nil
                    )
                }
            } catch {
                logger.error("Failed to create dummy directory at \(workingDirectory).\n \(error.localizedDescription)")
            }
        }
        #endif
        return Directory(workingDirectory: workingDirectory)
    }
}


public extension Application {
    /// A property specifying a `Directory`
    var directory: Directory {
        get { self.core.storage.directory }
        set { self.core.storage.directory = newValue }
    }
}
