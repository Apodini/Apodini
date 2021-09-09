//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniUtils
import OpenAPIKit

extension Dictionary where Key == String, Value == AnyEncodable {
    func mapToOpenAPICodable() -> [String: AnyCodable] {
        mapValues { AnyCodable.fromComplex($0) }
    }
}
