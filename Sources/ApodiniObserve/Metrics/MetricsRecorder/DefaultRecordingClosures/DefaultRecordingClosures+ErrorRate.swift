//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Metrics

public extension DefaultRecordingClosures {
    /// Records the error rate of a ``Handler``
    struct ErrorRate: DefaultRecorder {
        public static let before: BeforeRecordingClosure = { _, _, _ in }
        
        public static var afterException: AfterExceptionRecordingClosure? = { observeMetadata, _, error, _ in
            let counter = Metrics.Counter(
                label: "error_counter",
                dimensions: DefaultRecordingClosures.defaultDimensions(observeMetadata) +
                    [
                        ("error_type", String(describing: type(of: error))),
                        ("error_description", "\(error.localizedDescription)")
                    ]
            )
            
            counter.increment()
        }
    }
}
