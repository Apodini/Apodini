import Foundation
import NIO
import Apodini

/// Used to specify the directory in which the file is stored.
/// It is possible to pass a `subPath` relative to the passed directory.
/// If not existent, sub directories will be automatically created.
public struct UploadConfiguration {
    let directory: Directories
    let subPath: String?
    
    /// Creates a new `UploadConfiguration` with a given `Directory`
    /// and a sub path if needed.
    ///
    /// - parameters:
    ///     - directory: A  `Directories` object to specify the directory
    ///     - subPath: An optional subPath relative to the directory
    public init(_ directory: Directories, subPath: String? = nil) {
        self.directory = directory
        self.subPath = subPath
    }
    
    internal func validatedPath(_ app: Application, fileName: String) -> String {
        let mainPath = directory.path(for: app)
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
            print(error.localizedDescription)
            return mainPath.appending(fileName)
        }
    }
}
