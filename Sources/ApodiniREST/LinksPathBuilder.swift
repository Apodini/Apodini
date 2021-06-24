//
// Created by Andreas Bauer on 09.01.21.
//

import Apodini
import Foundation

struct LinksFormatter: RelationshipFormatter {
    let configuration: REST.Configuration

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

extension Apodini.Operation {
    /// Defines the order of formatting for the `LinksFormatter`.
    /// Bigger number means bigger priority.
    /// Higher priority will shadow lower priority.
    var linksOperationPriority: Int {
        switch self {
        case .delete:
            return 0
        case .update:
            return 1
        case .create:
            return 2
        case .read:
            return 3
        }
    }
}
