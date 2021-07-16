//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini
import ApodiniExtension
import Vapor
import Foundation


extension Vapor.Request: RequestBasis {
    public var debugDescription: String {
        "Vapor.Request: \(self.description)"
    }
    
    public var information: Set<AnyInformation> {
        Set(headers.map { key, rawValue in
            AnyInformation(key: key, rawValue: rawValue)
        })
    }
}
