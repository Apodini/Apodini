//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO



// MARK: Handler


extension Never: Encodable {
    /// Encodes an instance of `Self` to a `HTTPResponse
    ///
    /// `Never` must never be encoded!
    public func encode(to encoder: Encoder) throws {
        fatalError("Never should never be encoded")
    }
}


extension Never: Handler {
    public typealias Response = Never
    
    public func handle() -> Never {
        fatalError("Can't invoke endpoint with 'Never' response type")
    }
}


extension Handler where Response == Never {
    public func handle() -> Never {
        fatalError("Can't invoke endpoint with 'Never' response type")
    }
}



// MARK: Component


extension Never: Component {
    public var content: Never {
        fatalError()
    }
}


extension Component where Content == Never {
    public var content: Never {
        fatalError()
    }
}
