//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini


struct EmojiTransformer: ResponseTransformer {
    private let emojis: String
    private let growth: Int
    
    @State var amount: Int = 1
    
    
    init(emojis: String = "✅", growth: Int = 1) {
        self.emojis = emojis
        self.growth = growth
    }
    
    
    func transform(content string: String) -> String {
        defer { amount *= growth }
        return "\(String(repeating: emojis, count: amount)) \(string) \(String(repeating: emojis, count: amount))"
    }
}
