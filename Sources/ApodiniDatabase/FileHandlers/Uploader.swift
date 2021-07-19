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

/// A Handler which enables the upload of files and
/// images to a specified directory in Apodini.
public struct Uploader: Handler {
    @Environment(\.directory)
    private var directory: Directory
    
    @Environment(\.fileio)
    private var fileio: NonBlockingFileIO
    
    @Environment(\.eventLoopGroup)
    private var eventLoopGroup: EventLoopGroup
    
    @Parameter
    private var file: File
    
    private var config: UploadConfiguration
    
    /// Create a new `Uploader` with a customizable `UploadConfiguration`.
    ///
    /// - parameters:
    ///     - config: A  `UploadConfiguration` object
    public init(_ config: UploadConfiguration) {
        self.config = config
    }
    
    public func handle() throws -> EventLoopFuture<Response<String>> {
        let path = config.validatedPath(directory, fileName: file.filename)
        return fileio
            .openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: eventLoopGroup.next())
            .flatMap { handler in
                fileio
                    .write(fileHandle: handler, buffer: file.data, eventLoop: eventLoopGroup.next())
                    .flatMapThrowing { _ in
                        try handler.close()
                        return file.filename
                    }
            }
            .map { filename in
                .final(filename, status: .created)
            }
    }
}
