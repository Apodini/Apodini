//
// Created by Andreas Bauer on 23.08.21.
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
