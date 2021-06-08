//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestComponent: Component {
    var content: some Component {
        Text("Hello World!")
    }

    var metadata: Metadata {
        TestVoidComponentOnlyMetadata()

        ComponentVoids {
            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            Description("Hello World!")
        }

        ComponentOnlyVoids {
            TestVoidComponentOnlyMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            Description("Hello World!")
        }

        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
        HandlerVoids {
            TestVoidHandlerMetadata()
        }

        // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyComponentOnlyMetadata'
        WebServiceVoids {
            TestVoidWebServiceMetadata()
        }

        // error: no exact matches in call to static method 'buildExpression'
        ContentVoids {
            TestVoidContentMetadata()
        }
    }
}
