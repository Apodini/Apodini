import Foundation

extension String {
    /// `self` wrapped with apostrophes complying to json strings
    var asString: String {
        "\"\(self)\""
    }
}
