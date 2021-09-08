//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
        guard H.Response.self is CustomizableResponse.Type else {
            self.value = .requestResponse
            return
        }
        
        let isObserving = !blackboard[All<AnyObservedObject>.self].elements.isEmpty
        let hasState = !blackboard[All<AnyState>.self].elements.isEmpty
        let expectsInputStream = !blackboard[All<ConnectionEnvironment>.self].elements.isEmpty
        
        
        if expectsInputStream {
            if hasState {
                // likely aggregates input
                self.value = .clientSideStream
            } else {
                self.value = .bidirectionalStream
            }
        } else {
            if isObserving {
                self.value = .serviceSideStream
            } else {
                self.value = .requestResponse
            }
        }
    }
}

/// This protocol helps to detect if a `Handler.Response` type actually uses the
/// `Apodini.Response` struct.
///
/// This is important for detecting the `AutomaticCommunicationalPattern` correctly.
/// Only `Apodini.Response` and `EventLoopFuture`s that wrap an `Apodini.Response` (future)
/// should conform to `CustomizableResponse`.
private protocol CustomizableResponse { }

extension Response: CustomizableResponse { }

extension EventLoopFuture: CustomizableResponse where Value: CustomizableResponse { }

/// This protocol helps to detect if a `Handler` can maintain state.
private protocol AnyState { }

extension State: AnyState { }

/// This protocol helps to detect if a `Handler` has an `@Environment(\.connection)` that could
/// help to detect when the input-stream ends.
private protocol ConnectionEnvironment { }

extension Environment: ConnectionEnvironment where Value == Connection, Key == Application { }
