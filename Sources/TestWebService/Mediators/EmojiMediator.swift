//
//  EmojiMediator.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct EmojiMediator: ResponseTransformer {
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
