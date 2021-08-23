//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
public struct Text: Handler {
    private let text: String
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func handle() -> String {
        text
    }
}
