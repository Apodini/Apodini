//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

@testable import Apodini
@testable import ApodiniContext
import XCTest


final class SharedRepositoryTests: ApodiniTests {
    struct MockHandler: Handler {
        func handle() -> String { "" }
    }
    
    func testLazyInitialization() throws {
        struct RequiredKnowledge: KnowledgeSource {
            init<B>(_ sharedRepository: B) throws where B: SharedRepository { }
        }
        
        struct NotRequiredKnowledge: KnowledgeSource {
            init<B>(_ sharedRepository: B) throws where B: SharedRepository {
                XCTFail("Not required KnowledgeSource was initialized")
            }
        }
        
        let handler = MockHandler()
        let context = Context([:])
        
        let globalSharedRepository = GlobalSharedRepository<LazyHashmapSharedRepository>(app)
        
        let localSharedRepository = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: handler, context)
        
        _ = localSharedRepository[RequiredKnowledge.self]
    }

    func testKnowledgeSharing() throws {
        struct RandomKnowledge<T: TruthAnchor>: KnowledgeSource {
            var random: Int
            
            init<B>(_ sharedRepository: B) throws where B: SharedRepository {
                self.random = Int.random(in: Int.min...Int.max)
            }
        }
        
        enum Exporter1: TruthAnchor { }
        
        enum Exporter2: TruthAnchor { }
        
        let handler = MockHandler()
        let context = Context([:])
        
        let globalSharedRepository = GlobalSharedRepository<LazyHashmapSharedRepository>(app)
        
        let localSharedRepository = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: handler, context)
        
        // access to the same same `TruthAnchor` is shared
        XCTAssertEqual(localSharedRepository[RandomKnowledge<Exporter1>.self].random, localSharedRepository[RandomKnowledge<Exporter1>.self].random)
        XCTAssertEqual(localSharedRepository[RandomKnowledge<Exporter2>.self].random, localSharedRepository[RandomKnowledge<Exporter2>.self].random)
        // access to different `TruthAnchor`s is not shared
        XCTAssertNotEqual(
            localSharedRepository[RandomKnowledge<Exporter1>.self].random, localSharedRepository[RandomKnowledge<Exporter2>.self].random
        )
    }
}
