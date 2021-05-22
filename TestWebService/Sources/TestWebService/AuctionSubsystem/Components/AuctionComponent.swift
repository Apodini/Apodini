//
//  AuctionComponent.swift
//
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct AuctionComponent: Component {
    var content: some Component {
        Group("auction") {
            Auction()
                .identified(by: "placeBid")
                .response(EmojiTransformer(emojis: "🤑", growth: 2))
        }
    }
}
