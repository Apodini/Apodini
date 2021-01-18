import Foundation
import NIO

/// An internal struct to hold the data of a file uploaded to Apodini.
internal struct Input: Codable {
    var file: File
    
    /// Returns the data of the input as `ByteBuffer`
    var asByteBuffer: ByteBuffer {
        ByteBuffer(data: file.data)
    }
    
    /// The file extension, if it has one.
    var `extension`: String? {
        let parts = self.file.name.split(separator: ".")
        if parts.count > 1 {
            return parts.last.map(String.init)
        } else {
            return nil
        }
    }
    
    /// An internal struct to enable proper decoding
    struct File: Codable {
        var name: String
        var type: String?
        var data: Data
    }
}
