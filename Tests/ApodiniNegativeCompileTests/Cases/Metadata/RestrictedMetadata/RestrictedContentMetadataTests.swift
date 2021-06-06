//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestContent: Content {
    static var metadata: Metadata {
        TestVoidContentMetadata()

        ContentVoids {
            TestVoidContentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            Description("Hello World!")
            
            ContentVoids {
                TestVoidContentMetadata()
            }
        }

        // error: No exact matches in call to static method 'buildExpression'
        HandlerVoids {
            TestVoidHandlerMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        WebServiceVoids {
            TestVoidWebServiceMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        ComponentVoids {
            TestVoidComponentMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        ComponentOnlyVoids {
            TestVoidComponentOnlyMetadata()
        }
    }
}
