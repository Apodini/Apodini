//
// Created by Mathias Quintro on 14.03.21.
//

import Vapor

/// Modified version of FileMiddleWare from Vapor with the intention of allowing us to set multiple files
/// https://github.com/vapor/vapor/blob/main/Sources/Vapor/Middleware/FileMiddleware.swift
final class StaticFilesMiddleware: Middleware {
    private let prefix: String?
    private let publicDirectory: String

    init(prefix: String?, publicDirectory: String, ownerFile: StaticString) {
        self.prefix = prefix
        let directory: String

        var url = URL(fileURLWithPath: ownerFile.description)
        if FileManager.default.fileExists(atPath: url.path) {
            url.deleteLastPathComponent()
            while !FileManager.default.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
                url.deleteLastPathComponent()
            }

            let directoryCandidate = url.appendingPathComponent(publicDirectory).path
            if FileManager.default.fileExists(atPath: directoryCandidate) {
                directory = directoryCandidate
            } else {
                directory = publicDirectory
            }
        } else {
            directory = publicDirectory
        }

        self.publicDirectory = directory.hasSuffix("/") ? directory : directory + "/"
    }

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        // make a copy of the percent-decoded path
        guard var path = request.url.path.removingPercentEncoding else {
            return request.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        // protect against relative paths
        guard !path.contains("../") else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        // path must be relative.
        while path.hasPrefix("/") {
            path.removeFirst()
        }

        if let prefix = prefix {
            if path.hasPrefix("\(prefix)/") {
                path.removeFirst(prefix.count + 1)
            } else {
                return next.respond(to: request)
            }
        }

        while path.hasPrefix("/") {
            path.removeFirst()
        }

        // create absolute file path
        let filePath = self.publicDirectory + path

        // check if file exists and is not a directory
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            return next.respond(to: request)
        }

        // stream the file
        let res = request.fileio.streamFile(at: filePath)
        return request.eventLoop.makeSucceededFuture(res)
    }
}
