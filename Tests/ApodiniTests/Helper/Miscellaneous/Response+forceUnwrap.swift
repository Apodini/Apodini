//
// Created by Andreas Bauer on 23.01.21.
//

@testable import Apodini

extension Response {
    func forceUnwrap() -> Element {
        switch self {
        case let .final(element),
             let .send(element):
             return element
        default:
            fatalError("Failed to force unwrap \(self)!")
        }
    }
}
