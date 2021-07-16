//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
