import Foundation
import NIO
import Apodini

/// A Handler which enables the download of files saved to Apodini.
/// The `MultipleDownloader` will returns all file it finds under the given name or suffix
/// in the directories specified in the `DownloadConfiguration`.
/// If you want to download a single files, please refer to `SingleDownloader`
public struct MultipleDownloader: Handler {
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
    
    public func handle() throws -> EventLoopFuture<[File]> {
        let infos = try config.retrieveFileInfos(fileName, in: application)
        return eventLoop
            .flatten(
                infos.map { info in
                    application.fileio
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
            )
        //        for info in infos {
        //            eventLoop.flatten(<#T##futures: [EventLoopFuture<T>]##[EventLoopFuture<T>]#>)
        //            application.fileio.openFile(path: info.path, mode: .read, eventLoop: eventLoop).flatMap { handler in
        //                application.fileio
        //                    .read(fileHandle: handler, byteCount: info.readableBytes, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
        //                    .ma
        //                    .flatMapThrowing { buffer -> File in
        //                        try handler.close()
        //                        return File(data: buffer, filename: fileName)
        //                    }
        //            }
        //        }
        
    }
}
