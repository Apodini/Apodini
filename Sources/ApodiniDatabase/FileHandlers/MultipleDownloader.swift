//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO
import Apodini

/// A Handler which enables the download of files saved to Apodini.
/// The `MultipleDownloader` will returns all file it finds under the given name or suffix
/// in the directories specified in the `DownloadConfiguration`.
/// If you want to download a single files, please refer to `SingleDownloader`
public struct MultipleDownloader: Handler {
    @Environment(\.directory)
    private var directory: Directory
    
    @Environment(\.fileio)
    private var fileio: NonBlockingFileIO
    
    @Environment(\.eventLoopGroup)
    private var eventLoopGroup: any EventLoopGroup
    
    @Parameter(.http(.path))
    var fileName: String
    
    private var config: DownloadConfiguration
    
    /// Create a new `Downloader` with a customizable `DownloadConfiguration`.
    ///
    /// - parameters:
    ///     - config: A  `DownloadConfiguration` object
    public init(_ config: DownloadConfiguration) {
        self.config = config
    }
    
    public func handle() throws -> EventLoopFuture<[File]> {
        let infos = try config.retrieveFileInfos(fileName, in: directory)
        let eventLoop = eventLoopGroup.next()
        return eventLoop
            .flatten(
                infos.map { info in
                    readFile(for: info, on: eventLoop)
                }
            )
    }
    
    private func readFile(for info: FileInfo, on eventLoop: any EventLoop) -> EventLoopFuture<File> {
        fileio
            .openFile(path: info.path, mode: .read, eventLoop: eventLoop)
            .flatMap { handler in
                fileio
                    .read(fileHandle: handler, byteCount: info.readableBytes, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
                    .flatMapThrowing { buffer -> File in
                        try handler.close()
                        return File(data: buffer, filename: info.fileName)
                    }
            }
    }
}
