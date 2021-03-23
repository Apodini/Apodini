//
//  Application+Directory.swift
//
//
//  Created by Tim Gymnich on 22.12.20.
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// The MIT License (MIT)
//
// Copyright (c) 2020 Qutheory, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


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
