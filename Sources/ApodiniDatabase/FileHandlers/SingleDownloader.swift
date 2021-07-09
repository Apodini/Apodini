import Foundation
import Apodini
import NIO


/// A Handler which enables the download of files saved to Apodini.
/// The `SingleDownloader` will returns the first file it finds under the given name or suffix
/// in the directories specified in the `DownloadConfiguration`.
/// To download multiple files, please refer to `MultipleDownloader`.
public struct SingleDownloader: Handler {
    @Environment(\.directory)
    private var directory: Directory
    
    @Environment(\.fileio)
    private var fileio: NonBlockingFileIO
    
    @Environment(\.eventLoopGroup)
    private var eventLoopGroup: EventLoopGroup
    
    @Parameter(.http(.path))
    var fileName: String
    
    @Binding private var config: DownloadConfiguration
    
    /// Create a new `Downloader` with a customizable `DownloadConfiguration`.
    ///
    /// - parameters:
    ///     - config: A  `DownloadConfiguration` object
    public init(_ config: DownloadConfiguration) {
        self._config = .constant(config)
    }
    
    public func handle() throws -> EventLoopFuture<File> {
        let info = try config.retrieveFileInfo(fileName, in: directory)
        return fileio
            .openFile(path: info.path, mode: .read, eventLoop: eventLoopGroup.next())
            .flatMap { handler in
                fileio
                    .read(fileHandle: handler, byteCount: info.readableBytes, allocator: ByteBufferAllocator(), eventLoop: eventLoopGroup.next())
                    .flatMapThrowing { buffer -> File in
                        try handler.close()
                        return File(data: buffer, filename: fileName)
                    }
            }
    }
}
