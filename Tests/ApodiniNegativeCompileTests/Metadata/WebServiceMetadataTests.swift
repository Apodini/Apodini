//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestWebService: WebService {
    var content: some Component {
        Text("Hello World!")
    }

    var metadata: Metadata {
        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        TestVoidHandlerMetadata()

        TestVoidWebServiceMetadata()

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        TestVoidComponentOnlyMetadata()

        TestVoidComponentMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidContentMetadata()

        Block {
            TestVoidWebServiceMetadata()
        }

        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()
        }

        StandardWebServiceMetadataBlock {
            // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
            TestVoidHandlerMetadata()

            TestVoidWebServiceMetadata()

            // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
            TestVoidComponentOnlyMetadata()

            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidContentMetadata()
        }

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        StandardComponentOnlyMetadataBlock {
            TestVoidComponentOnlyMetadata()
        }

        StandardComponentMetadataBlock {
            TestVoidComponentMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardContentMetadataBlock {
            TestVoidContentMetadata()
        }
    }
}
