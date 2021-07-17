//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//       

/// This file holds the global configurations used by the `NegativeTestRunner`.
/// It defines which target are executed and optionally restricts what
/// test cases of a target are executed.


let configurations: TestRunnerConfiguration = [
    .target(
        name: "ApodiniNegativeCompileTests",
        configurations: [
            // Linux has issues compiling malformed resultBuilders, resulting in one compiler error
            // "failed to produce diagnostic for expression; please file a bug report" for the whole block
            // when too many errors occurred inside. Therefore linux platform is excluded.
            .testCase("Metadata", runningOn: .exclude(.linux))
        ]
    )
]
