//
// Created by Andi on 25.12.20.
//

@testable import Apodini

struct EmojiMediator: EncodableResponseTransformer {
    private let emojis: String

    init(emojis: String = "✅") {
        self.emojis = emojis
    }

    func transform(response: String) -> String {
        "\(emojis) \(response) \(emojis)"
    }
}
