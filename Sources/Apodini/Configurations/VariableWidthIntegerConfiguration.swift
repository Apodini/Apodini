//
//  Created by Nityananda on 28.01.21.
//

public struct VariableWidthIntegerConfiguration: Configuration {
    // MARK: Nested Types
    public enum Option: Int {
        case thirtyTwo = 32
        case sixtyFour = 64
    }
    
    enum Key: StorageKey {
        typealias Value = Option
    }
    
    // MARK: Properties
    let option: Option
    
    // MARK: Initialization
    public init(_ option: Option) {
        self.option = option
    }
    
    // MARK: Methods
    public func configure(_ app: Application) {
        guard option.rawValue <= Int.bitWidth else {
            preconditionFailure(
                """
                \(option) requires architecture to have a wider integer bit width. \
                Try using a smaller option.
                """
            )
        }
        
        app.storage[Key.self] = option
    }
}
