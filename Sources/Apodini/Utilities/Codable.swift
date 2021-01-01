//
// Created by Andi on 01.01.21.
//

import Foundation
import NIO

protocol EncodableContainer: Encodable {
    func accept<Visitor: EncodableContainerVisitor>(_ visitor: Visitor) -> Visitor.Output
}

protocol EncodableContainerVisitor {
    associatedtype Output

    func visit<Value: Encodable>(_ action: Action<Value>) -> Output
}


protocol EncodableValue: Encodable {
    func accept<Visitor: EncodableValueVisitor>(_ visitor: Visitor) -> Visitor.Output
}

protocol EncodableValueVisitor {
    associatedtype Output

    func visit<Value: Encodable>(_ future: EventLoopFuture<Value>) -> Output
}

// MARK: Encodable
extension EventLoopFuture: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        fatalError("Can't encode a EventLoop Future synchronous! Please use the .encode(...) returning an EventLoopFuture")
    }
}

// MARK: Apodini Encodable Value
extension EventLoopFuture: EncodableValue where Value: Encodable {
    func accept<Visitor: EncodableValueVisitor>(_ visitor: Visitor) -> Visitor.Output {
        visitor.visit(self)
    }
}
