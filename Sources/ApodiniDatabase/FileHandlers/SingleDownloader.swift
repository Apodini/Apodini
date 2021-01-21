import Foundation
import Apodini
import NIO


/// A Handler which enables the download of files saved to Apodini.
/// The `SingleDownloader` will returns the first file it finds under the given name or suffix
/// in the directories specified in the `DownloadConfiguration`.
/// To download multiple files, please refer to `MultipleDownloader`.
public struct SingleDownloader: Handler {
    @Environment(\.application)
    private var application: Application
    
    @Parameter(.http(.path))
    var fileName: String
    
    private var eventLoop: EventLoop {
        application.eventLoopGroup.next()
    }
    
    private var config: DownloadConfiguration
    
    /// Create a new `Downloader` with a customizable `DownloadConfiguration`.
    ///
    /// - parameters:
    ///     - config: A  `DownloadConfiguration` object
    public init(_ config: DownloadConfiguration) {
        self.config = config
    }
    
    public func handle() throws -> EventLoopFuture<File> {
        guard let info = try config.retrieveFileInfo(fileName, in: application) else {
            throw NSError()
        }
        return application.fileio
            .openFile(path: info.path, mode: .read, eventLoop: eventLoop)
            .flatMap { handler in
                application.fileio
                    .read(fileHandle: handler, byteCount: info.readableBytes, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
                    .flatMapThrowing { buffer -> File in
                        try handler.close()
                        return File(data: buffer, filename: fileName)
                    }
            }
    }
}
