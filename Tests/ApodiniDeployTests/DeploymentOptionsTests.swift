//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
@testable import Apodini
import ApodiniDeployBuildSupport

final class DeploymentOptionsTests: XCTApodiniTest {
    struct MemorySizeMetadata: HandlerMetadataBlock {
        var metadata: Metadata {
            Memory(.mb(128))
            Memory(.mb(256))
        }
    }

    struct TimeoutMetadata: HandlerMetadataBlock {
        var metadata: Metadata {
            Timeout(.seconds(60))
            Timeout(.minutes(2))
        }
    }

    func retrieveOptions<Block: HandlerMetadataBlock>(from block: Block) -> PropertyOptionSet<DeploymentOptionNamespace> {
        let visitor = SyntaxTreeVisitor()

        block.collectMetadata(visitor)
        let context = visitor.currentNode.export()

        return context.get(valueFor: DeploymentOptionsContextKey.self) ?? .init()
    }

    func testMemorySizeMetadata() {
        let options = retrieveOptions(from: MemorySizeMetadata())

        let memory = options.option(for: .memorySize)
        let timeout = options.option(for: .timeoutValue)

        XCTAssertEqual(memory.rawValue, 256)
        XCTAssertEqual(timeout.rawValue, TimeoutValue.defaultValue.rawValue)
    }

    func testTimeoutMetadata() {
        let options = retrieveOptions(from: TimeoutMetadata())

        let memory = options.option(for: .memorySize)
        let timeout = options.option(for: .timeoutValue)

        XCTAssertEqual(memory.rawValue, MemorySize.defaultValue.rawValue)
        XCTAssertEqual(timeout.rawValue, 120)
    }
}
