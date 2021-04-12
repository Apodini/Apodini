//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation

//===----------------------------------------------------------------------===//

/// A marker protocol used to determine whether a value is a `String`-keyed `Dictionary`
/// containing `Encodable` values (in which case it should be exempt from key conversion strategies).
///
/// NOTE: The architecture and environment check is due to a bug in the current (2018-08-08) Swift 4.2
/// runtime when running on i386 simulator. The issue is tracked in https://bugs.swift.org/browse/SR-8276
/// Making the protocol `internal` instead of `private` works around this issue.
/// Once SR-8276 is fixed, this check can be removed and the protocol always be made private.


#if arch(i386) || arch(arm)
internal protocol _JSONStringDictionaryEncodableMarker { }
#else
private protocol _JSONStringDictionaryEncodableMarker { }
#endif

extension Dictionary: _JSONStringDictionaryEncodableMarker where Key == String, Value: Encodable { }


extension _JSONEncoder {
    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    func box(_ value: Bool) -> NSObject { NSNumber(value: value) }
    func box(_ value: Int) -> NSObject { NSNumber(value: value) }
    func box(_ value: Int8) -> NSObject { NSNumber(value: value) }
    func box(_ value: Int16) -> NSObject { NSNumber(value: value) }
    func box(_ value: Int32) -> NSObject { NSNumber(value: value) }
    func box(_ value: Int64) -> NSObject { NSNumber(value: value) }
    func box(_ value: UInt) -> NSObject { NSNumber(value: value) }
    func box(_ value: UInt8) -> NSObject { NSNumber(value: value) }
    func box(_ value: UInt16) -> NSObject { NSNumber(value: value) }
    func box(_ value: UInt32) -> NSObject { NSNumber(value: value) }
    func box(_ value: UInt64) -> NSObject { NSNumber(value: value) }
    func box(_ value: Float) -> NSObject { NSNumber(value: value) }
    func box(_ value: Double) -> NSObject { NSNumber(value: value) }
    func box(_ value: String) -> NSObject { NSString(string: value) }
    func box(_ value: Date) -> NSObject { NSNumber(value: value.timeIntervalSince1970) }
    func box(_ value: Data) -> NSObject { NSString(string: value.base64EncodedString()) }


    func box(_ dict: [String: Encodable]) throws -> NSObject? {
        let depth = self.storage.count
        let result = self.storage.pushKeyedContainer()
        do {
            for (key, value) in dict {
                self.codingPath.append(JSONKey(stringValue: key, intValue: nil))
                defer { self.codingPath.removeLast() }
                result[key] = try box(value)
            }
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }

    func box(_ value: Encodable) throws -> NSObject {
        try self.box_(value) ?? NSDictionary()
    }

    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    func box_(_ value: Encodable) throws -> NSObject? {
        // Disambiguation between variable and function is required due to
        // issue tracked at: https://bugs.swift.org/browse/SR-1846
        let type = Swift.type(of: value)
        if type == Date.self || type == NSDate.self {
            // Respect Date encoding strategy
            return self.box((value as! Date))
        } else if type == Data.self || type == NSData.self {
            // Respect Data encoding strategy
            return self.box((value as! Data))
        } else if type == URL.self || type == NSURL.self {
            // Encode URLs as single strings.
            return self.box((value as! URL).absoluteString)
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            // JSONSerialization can natively handle NSDecimalNumber.
            return (value as! NSDecimalNumber)
        } else if value is _JSONStringDictionaryEncodableMarker {
            return try self.box(value as! [String: Encodable])
        }

        // The value should request a container from the __JSONEncoder.
        let depth = self.storage.count
        
        do {
            try value.encode(to: self)
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }
}
