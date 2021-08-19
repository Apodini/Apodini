//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Metrics

public extension DefaultRecordingClosures {
    /// Records the request counter of a ``Handler``
    struct RequestCounter: DefaultRecorder {
        public static let before: BeforeRecordingClosure = { observeMetadata, _, _ in
            let counter = Metrics.Counter(
                label: "request_counter",
                dimensions: DefaultRecordingClosures.defaultDimensions(observeMetadata)
            )
            
            counter.increment()
        }
    }
}
