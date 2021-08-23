//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
