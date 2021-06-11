//
// Created by Andreas Bauer on 02.06.21.
//

import Foundation

extension FileManager {
    /// Checks if a directory exists.
    /// - Parameter url: The `URL` to the file which should be checked.
    /// - Returns: Returns true if the file located under the URL exists AND is a directory.
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
