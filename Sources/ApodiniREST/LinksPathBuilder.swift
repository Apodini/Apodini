//
// Created by Andreas Bauer on 09.01.21.
//

import Foundation

struct LinksFormatter: RelationshipFormatter {
    let configuration: RESTConfiguration

    func reduce(representation: String, of: RelationshipDestination, into: inout [String: String]) {
        into[of.name] = representation
    }

    func format(destination: RelationshipDestination) -> String? {
        if destination.hideLink {
            return nil
        }

        return configuration.uriPrefix + destination.destinationPath.asPathString(parameterEncoding: .valueOrName)
    }
}
