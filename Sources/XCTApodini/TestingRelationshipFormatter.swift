//
// Created by Andreas Bauer on 23.01.21.
//

@testable import Apodini

struct TestingRelationshipFormatter: RelationshipFormatter {
    var hideHidden: Bool = false

    func format(destination: RelationshipDestination) -> String? {
        (destination.hideLink ? "hidden:" : "") + destination.destinationPath.asPathString(parameterEncoding: .valueOrName)
    }

    func reduce(representation: String, of: RelationshipDestination, into: inout [String: String]) {
        if of.hideLink && hideHidden {
            return
        }

        into[of.name + ":\(of.operation)"] = representation
    }
}
