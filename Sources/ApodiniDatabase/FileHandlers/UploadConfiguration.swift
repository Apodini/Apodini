import Foundation
import NIO
import Apodini
import Logging

/// Used to specify the directory in which the file is stored.
/// It is possible to pass a `subPath` relative to the passed directory.
/// If not existent, sub directories will be automatically created.
public struct UploadConfiguration {
    @Environment(\.logger)
    var logger: Logger
    
    private let directories: Directories
    private let subPath: String?
    
    /// Creates a new `UploadConfiguration` with a given `Directory`
    /// and a sub path if needed.
    ///
    /// - parameters:
    ///     - directory: A  `Directories` object to specify the directory
    ///     - subPath: An optional subPath relative to the directory
    public init(_ directories: Directories, subPath: String? = nil) {
        self.directories = directories
        self.subPath = subPath
    }
    
    internal func validatedPath(_ directory: Directory, fileName: String) -> String {
        let mainPath = directories.path(for: directory)
        guard let subPath = subPath else {
            return mainPath.appending(fileName)
        }
        do {
            let fileManager = FileManager.default
            
            var url = URL(fileURLWithPath: mainPath)
            for pathComponent in subPath.pathComponents {
                url.appendPathComponent(pathComponent.description)
                if !fileManager.fileExists(atPath: url.relativePath) {
                    try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                }
            }
            return url.relativePath.appending("/").appending(fileName)
        } catch {
            logger.error("\(error.localizedDescription)")
            return mainPath.appending(fileName)
        }
    }
}
