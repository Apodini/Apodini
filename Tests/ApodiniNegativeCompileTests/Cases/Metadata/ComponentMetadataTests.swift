//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestComponent: Component {
    var content: some Component {
        Text("Hello World!")
    }

    var metadata: Metadata {
        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
        TestVoidHandlerMetadata()

        // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
        TestVoidWebServiceMetadata()

        TestVoidComponentOnlyMetadata()

        TestVoidComponentMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidContentMetadata()

        Block {
            TestVoidComponentOnlyMetadata()

            TestVoidComponentMetadata()
        }

        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()
        }

        // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
        StandardWebServiceMetadataBlock {
            TestVoidWebServiceMetadata()
        }

        StandardComponentOnlyMetadataBlock {
            // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
            TestVoidHandlerMetadata()

            // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
            TestVoidWebServiceMetadata()

            TestVoidComponentOnlyMetadata()

            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidContentMetadata()
        }

        StandardComponentMetadataBlock {
            // error: No exact matches in call to static method 'buildExpression'
            TestVoidHandlerMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidWebServiceMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidComponentOnlyMetadata()

            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidContentMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardContentMetadataBlock {
            TestVoidContentMetadata()
        }
    }
}
