//
// Created by Mathias Quintro on 14.03.21.
//

import Foundation
import Vapor
import Apodini
import ApodiniVaporSupport

public struct StaticFiles: Configuration {
    private let fileMiddleware: Middleware

    public init(publicDirectory: String, at path: String..., ownerFile: StaticString = #file) {
        fileMiddleware = StaticFilesMiddleware(prefix: path.isEmpty ? nil : path.joined(separator: "/"),
                                               publicDirectory: publicDirectory,
                                               ownerFile: ownerFile)
    }

    public func configure(_ app: Apodini.Application) {
        app.vapor.app.middleware.use(fileMiddleware)
    }
}
