import Foundation
import Apodini

/// Used to specify the directory in which the file is stored.
/// It is possible to pass a `subPath` relative to the passed directory.
/// If not existent, sub directories will be automatically created.
public struct DownloadConfiguration {
    private let directories: [Directories]
    
    /// Creates a new `UploadConfiguration` with a given `Directory`
    /// and a sub path if needed.
    ///
    /// - parameters:
    ///     - directory: A  `Directories` object to specify the directory
    ///     - subPath: An optional subPath relative to the directory
    public init(_ directories: Directories...) {
        if directories.contains(.default) {
            self.directories = [.public, .resource, .working]
        } else {
            self.directories = directories
        }
    }
    
    /// An internal function to retrieve the file info. It looks for a file under the fiven name in the `Directories` specified in the initializer.
    /// It returns a `FileInfo` containing the readable bytes of the file as well as the path to it.
    internal func retrieveFileInfo(_ fileName: String, in directory: Directory) throws -> FileInfo {
        let fileManager = FileManager.default
        let searchableDirectories: [String] = directories.map { $0.path(for: directory) }
        
        for dir in searchableDirectories {
            #if Xcode || DEBUG || RELEASE_TESTING
            // For an explanation, see below
            guard fileManager.fileExists(atPath: dir) else {
                continue
            }
            #endif
            let subPaths = try fileManager.subpathsOfDirectory(atPath: dir)
            for subDir in subPaths {
                let path = dir.appending(subDir)
                if subDir.hasSuffix(fileName) && fileManager.isReadableFile(atPath: path) {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    return FileInfo(readableBytes: data.count, path: path)
                }
            }
        }
        throw DecodingError.valueNotFound(
            FileInfo.self,
            DecodingError.Context(codingPath: [], debugDescription: "Failed to retrieve the info for the file named \(fileName)." +
                                        "Possible issues: File was not found under \(directories.debugDescription)")
        )
    }
    
    /// An internal function to retrieve the file infos for the given filename or extension. It looks for all file under the fiven name in the `Directories` specified in the initializer.
    /// It returns an array of `FileInfo` objects containing the readable bytes of the file as well as the path to it.
    internal func retrieveFileInfos(_ fileName: String, in directory: Directory) throws -> [FileInfo] {
        let fileManager = FileManager.default
        let searchableDirectories: [String] = directories.map { $0.path(for: directory) }
        var infos: [FileInfo] = []
        
        for dir in searchableDirectories {
            #if Xcode || DEBUG || RELEASE_TESTING
            // As we are in Xcode, we created only a dummy public directory.
            // See Application+Directory.swift
            // This means that `resource` and `working` are missing.
            // To test the handlers properly, we need to first check if the directory exists.
            // On Prod its better to forward the missing directory error to the user.
            guard fileManager.fileExists(atPath: dir) else {
                continue
            }
            #endif
            let subPaths = try fileManager.subpathsOfDirectory(atPath: dir)
            for subDir in subPaths {
                let path = dir.appending(subDir)
                if subDir.hasSuffix(fileName) &&
                    fileManager.isReadableFile(atPath: path) &&
                    !infos.contains(where: { $0.path == path }) {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    infos.append(FileInfo(readableBytes: data.count, path: path))
                }
            }
        }
        return infos
    }
}
/// An internal struct that contains the number of readable bytes
/// and the path to the file
internal struct FileInfo {
    let readableBytes: Int
    let path: String
    
    var fileName: String {
        String(path.split(separator: "/").last ?? "")
    }
}
