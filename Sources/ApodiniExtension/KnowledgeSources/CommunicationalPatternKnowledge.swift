//
//  CommunicationalPatternKnowledge.swift
//  
//
//  Created by Max Obermeier on 30.06.21.
//

import Foundation
import Apodini


extension CommunicationalPattern: KnowledgeSource {
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self = blackboard[ExplicitCommunicationalPattern.self].value ?? blackboard[AutomaticCommunicationalPattern.self].value
    }
}

private struct ExplicitCommunicationalPattern: OptionalContextKeyKnowledgeSource {
    typealias Key = CommunicationalPatternContextKey
    
    let value: CommunicationalPattern?
    
    init(from value: CommunicationalPattern?) throws {
        self.value = value
    }
}

struct AutomaticCommunicationalPattern: HandlerKnowledgeSource {
    let value: CommunicationalPattern
    
    init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
        if H.Response.self is CustomizableResponse.Type {
            self.value = .bidirectionalStream
        } else {
            self.value = .requestResponse
        }
    }
}

/// This protocol is helps to detect if a `Handler.Response` type actually uses the
/// `Apodini.Response` struct.
///
/// This is important for detecting the `AutomaticCommunicationalPattern` correctly.
/// Only `Apodini.Response` and `EventLoopFuture`s that wrap an `Apodini.Response` (future)
/// should conform to `CustomizableResponse`.
private protocol CustomizableResponse { }

extension Response: CustomizableResponse { }

extension EventLoopFuture: CustomizableResponse where Value: CustomizableResponse { }
