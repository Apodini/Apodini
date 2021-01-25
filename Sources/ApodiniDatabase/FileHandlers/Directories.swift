import Foundation
import Apodini

/// A enum to tell the `UploadConfiguration` in which directory the file should be stored.
public enum Directories: String {
    /// The public directory of the web service
    case `public`
    /// The working directory of the web service
    case working
    /// The resource directory of the web service
    case resource
    /// The default directory. On Upload this is the `Public` dir.
    /// On Download this means it looks in all dirs for the file.
    case `default`
    
    /// Returns the path of the directory of `Self`for the `Application` object
    func path(for directory: Directory) -> String {
        switch self {
        case .public:
            return directory.publicDirectory
        case .resource:
            return directory.resourcesDirectory
        case .working:
            return directory.workingDirectory
        case .default:
            return directory.publicDirectory
        }
    }
}
