import Foundation
import NIO
import Apodini

/// A Handler which enables the upload of files and
/// images to a specified directory in Apodini.
public struct Uploader: Handler {
    @Environment(\.application)
    private var application: Application
    
    @Parameter
    private var file: File
    
    private var eventLoop: EventLoop {
        application.eventLoopGroup.next()
    }
    
    private var config: UploadConfiguration
    
    /// Create a new `Uploader` with a customizable `UploadConfiguration`.
    ///
    /// - parameters:
    ///     - config: A  `UploadConfiguration` object
    public init(_ config: UploadConfiguration) {
        self.config = config
    }
    
    public func handle() throws -> EventLoopFuture<String> {
        let path = config.validatedPath(application, fileName: file.filename)
        return application.fileio
            .openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: eventLoop)
            .flatMap { handler in
                application.fileio
                    .write(fileHandle: handler, buffer: file.data, eventLoop: eventLoop)
                    .flatMapThrowing { _ in
                        try handler.close()
                        return file.filename
                    }
            }
    }
}
