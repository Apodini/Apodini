//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini

struct EmojiMediator: ResponseTransformer {
    @Binding private var emojis: String

    init(emojis: String = "✅") {
        self._emojis = .constant(emojis)
    }

    func transform(content string: String) -> String {
        "\(emojis) \(string) \(emojis)"
    }
}
