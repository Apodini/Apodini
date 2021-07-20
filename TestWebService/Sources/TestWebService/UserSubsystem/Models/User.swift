//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini


struct User: Content, Identifiable {
    var id: Int
    var writtenId = UUID()

    static var metadata: Metadata {
        References<Post>(as: "written", identifiedBy: \.writtenId)
    }
}
