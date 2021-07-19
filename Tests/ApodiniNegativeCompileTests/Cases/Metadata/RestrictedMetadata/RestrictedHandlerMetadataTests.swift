//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
