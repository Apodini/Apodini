//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini

struct EmojiMediator: ResponseTransformer {
    private let emojis: String

    init(emojis: String = "✅") {
        self.emojis = emojis
    }

    func transform(content string: String) -> String {
        "\(emojis) \(string) \(emojis)"
    }
}
