//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestWebService: WebService {
    var content: some Component {
        Text("Hello World!")
    }

    var metadata: Metadata {
        TestVoidWebServiceMetadata()

        WebServiceVoids {
            TestVoidWebServiceMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            Description("Hello World!")
        }

        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        HandlerVoids {
            TestVoidHandlerMetadata()
        }

        ComponentVoids {
            TestVoidComponentMetadata()
        }

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        ComponentOnlyVoids {
            TestVoidComponentOnlyMetadata()
        }

        // error: no exact matches in call to static method 'buildExpression'
        ContentVoids {
            TestVoidContentMetadata()
        }
    }
}
