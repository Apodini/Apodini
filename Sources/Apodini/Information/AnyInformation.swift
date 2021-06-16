//
//  AnyInformation.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//


/// Type erasured `Information`
/// Information describes additional metadata that can be attached to a `Response` or can be found in the `ConnectionContext` in the `@Environment` of a `Handler`.
public struct AnyInformation {
    /// A key identifying the type erasued `Information` type
    public let key: String
    /// The value associated with the type erasued `Information` type
    let value: Any
    /// The raw `String` representation associated with the type erasued `Information` type
    public let rawValue: String
    
    
    /// Create a new `AnyInformation` instance using an `Information` instance
    public init<I: Information>(_ information: I) {
        self.key = I.key
        self.value = information.value
        self.rawValue = information.rawValue
    }
    
    /// Create a new `AnyInformation` instance using a `key` `value` pair.
    /// - Parameters:
    ///   - key: The key of the `Information`
    ///   - rawValue: The raw `String` value of the `Information`
    public init(key: String, rawValue: String) {
        switch key {
        case Authorization.key:
            guard let authorization = Authorization(rawValue: rawValue) else {
                fallthrough
            }
            self = .init(authorization)
            return
        case Cookies.key:
            guard let cookies = Cookies(rawValue: rawValue) else {
                fallthrough
            }
            self = .init(cookies)
            return
        case ETag.key:
            guard let etag = ETag(rawValue: rawValue) else {
                fallthrough
            }
            self = .init(etag)
            return
        case Expires.key:
            guard let expires = Expires(rawValue: rawValue) else {
                fallthrough
            }
            self = .init(expires)
            return
        case RedirectTo.key:
            guard let redirectTo = RedirectTo(rawValue: rawValue) else {
                fallthrough
            }
            self = .init(redirectTo)
            return
        default:
            self.key = key
            self.value = rawValue
            self.rawValue = rawValue
        }
    }
    
    
    func typed<I: Information>(_ type: I.Type = I.self) -> I? {
        guard let value = value as? I.Value else {
            return nil
        }
        
        return I(value)
    }
}


extension AnyInformation: Hashable {
    public static func == (lhs: AnyInformation, rhs: AnyInformation) -> Bool {
        lhs.key == rhs.key
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}


extension AnyInformation {
    /// A custom `Information` that is defined by a key and a rawValue expressed by a `String`
    public static func custom(key: String, rawValue: String) -> AnyInformation {
        AnyInformation(key: key, rawValue: rawValue)
    }
}
