//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestContent: Content {
    static var metadata: Metadata {
        // error: No exact matches in call to static method 'buildExpression'
        TestVoidHandlerMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidWebServiceMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidComponentOnlyMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidComponentMetadata()

        TestVoidContentMetadata()

        Block {
            TestVoidContentMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardWebServiceMetadataBlock {
            TestVoidWebServiceMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardComponentOnlyMetadataBlock {
            TestVoidComponentOnlyMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardComponentMetadataBlock {
            TestVoidComponentMetadata()
        }

        StandardContentMetadataBlock {
            // error: No exact matches in call to static method 'buildExpression'
            TestVoidHandlerMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidWebServiceMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidComponentOnlyMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidComponentMetadata()

            TestVoidContentMetadata()
        }
    }
}
