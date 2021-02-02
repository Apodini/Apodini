//
// Created by Andreas Bauer on 23.01.21.
//

import Apodini

public struct TestingRelationshipFormatter: RelationshipFormatter {
    var hideHidden: Bool

    public init(hideHidden: Bool = false) {
        self.hideHidden = hideHidden
    }

    public func format(destination: RelationshipDestination) -> String? {
        (destination.hideLink ? "hidden:" : "") + destination.destinationPath.asPathString(parameterEncoding: .valueOrName)
    }

    public func reduce(representation: String, of: RelationshipDestination, into: inout [String: String]) {
        if of.hideLink && hideHidden {
            return
        }

        into[of.name + ":\(of.operation)"] = representation
    }
}
