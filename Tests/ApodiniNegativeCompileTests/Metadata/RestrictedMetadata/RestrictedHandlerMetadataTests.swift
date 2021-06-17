//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestHandler: Handler {
    func handle() -> String {
        "Hello World!"
    }

    var metadata: Metadata {
        TestVoidHandlerMetadata()

        HandlerVoids {
            TestVoidHandlerMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            Description("Hello World!")

            HandlerVoids {
                TestVoidHandlerMetadata()
            }
        }

        // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
        WebServiceVoids {
            TestVoidWebServiceMetadata()
        }

        ComponentVoids {
            TestVoidComponentMetadata()
        }

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
        ComponentOnlyVoids {
            TestVoidComponentOnlyMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        ContentVoids {
            TestVoidContentMetadata()
        }
    }
}
