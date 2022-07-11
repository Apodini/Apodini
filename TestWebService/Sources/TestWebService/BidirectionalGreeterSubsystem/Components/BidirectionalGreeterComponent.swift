//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

struct BidirectionalGreeterComponent: Component {
    var content: some Component {
        Group("bigreeter") {
            BidirectionalGreeter()
        }
    }
}
