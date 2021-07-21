//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

@testable import Apodini
import XCTest


final class BlackboardTests: ApodiniTests {
    struct MockHandler: Handler {
        func handle() -> String { "" }
    }
    
    func testLazyInitialization() throws {
        struct RequiredKnowledge: KnowledgeSource {
            init<B>(_ blackboard: B) throws where B: Blackboard { }
        }
        
        struct NotRequiredKnowledge: KnowledgeSource {
            init<B>(_ blackboard: B) throws where B: Blackboard {
                XCTFail("Not required KnowledgeSource was initialized")
            }
        }
        
        let handler = MockHandler()
        let context = Context([:])
        
        let globalBlackboard = GlobalBlackboard<LazyHashmapBlackboard>(app)
        
        let localBlackboard = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: handler, context)
        
        _ = localBlackboard[RequiredKnowledge.self]
    }

    func testKnowledgeSharing() throws {
        struct RandomKnowledge<T: TruthAnchor>: KnowledgeSource {
            var random: Int
            
            init<B>(_ blackboard: B) throws where B: Blackboard {
                self.random = Int.random(in: Int.min...Int.max)
            }
        }
        
        enum Exporter1: TruthAnchor { }
        
        enum Exporter2: TruthAnchor { }
        
        let handler = MockHandler()
        let context = Context([:])
        
        let globalBlackboard = GlobalBlackboard<LazyHashmapBlackboard>(app)
        
        let localBlackboard = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: handler, context)
        
        // access to the same same `TruthAnchor` is shared
        XCTAssertEqual(localBlackboard[RandomKnowledge<Exporter1>.self].random, localBlackboard[RandomKnowledge<Exporter1>.self].random)
        XCTAssertEqual(localBlackboard[RandomKnowledge<Exporter2>.self].random, localBlackboard[RandomKnowledge<Exporter2>.self].random)
        // access to different `TruthAnchor`s is not shared
        XCTAssertNotEqual(localBlackboard[RandomKnowledge<Exporter1>.self].random, localBlackboard[RandomKnowledge<Exporter2>.self].random)
    }
}
