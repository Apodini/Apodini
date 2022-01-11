import Foundation
import PathKit

public extension String {
    
    /// Returns encoded data of `self`
    func data(_ encoding: Encoding = .utf8) -> Data {
        data(using: encoding) ?? .init()
    }
}
