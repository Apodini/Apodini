#if os(Linux)
import Glibc
#else
import Darwin.C
#endif
import Foundation

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
        self.workingDirectory = workingDirectory.finished(with: "/")
        self.resourcesDirectory = self.workingDirectory + "Resources/"
        self.publicDirectory = self.workingDirectory + "Public/"
    }
    
    /// Creates a `Directory` by deriving a working directory using the `#file` variable or `getcwd` method.
    ///
    /// - returns: The derived `Directory` if it could be created, otherwise just "./".
    public static func detect() -> Directory {
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
            print("No custom working directory set for this scheme")
            print("Setting dummy directory for debug purposes")
            do {
                if !FileManager.default.fileExists(atPath: workingDirectory + "/Public/") {
                    try FileManager.default.createDirectory(atPath: workingDirectory + "/Public/",
                                                            withIntermediateDirectories: false,
                                                            attributes: nil)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        #endif
        print(workingDirectory)
        return Directory(workingDirectory: workingDirectory)
    }
}

fileprivate extension String {
    func finished(with string: String) -> String {
        if !self.hasSuffix(string) {
            return self + string
        } else {
            return self
        }
    }
}

public extension Application {
    /// A property specifying a `Directory`
    var directory: Directory {
        get { self.core.storage.directory }
        set { self.core.storage.directory = newValue }
    }
}
