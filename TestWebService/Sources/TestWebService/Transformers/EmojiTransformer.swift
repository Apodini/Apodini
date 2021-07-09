//
//  EmojiTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct EmojiTransformer: ResponseTransformer {
    @Binding private var emojis: String
    @Binding private var growth: Int
    
    @State var amount: Int = 1
    
    
    init(emojis: String = "✅", growth: Int = 1) {
        self._emojis = .constant(emojis)
        self._growth = .constant(growth)
    }
    
    
    func transform(content string: String) -> String {
        defer { amount *= growth }
        return "\(String(repeating: emojis, count: amount)) \(string) \(String(repeating: emojis, count: amount))"
    }
}
