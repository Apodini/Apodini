//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Metrics
import Dispatch

public extension DefaultRecordingClosures {
    /// Records the response time of a `Handler`
    struct ResponseTime: DefaultRecorder {
        public static let before: DefaultRecordingClosures.Types.Before = { _, _, relay in
            relay["sinceDispatchTimeNanoseconds"] = String(DispatchTime.now().uptimeNanoseconds)
        }
        
        public static let after: DefaultRecordingClosures.Types.After? = { observeMetadata, _, relay in
            let timer = Metrics.Timer(
                label: "response_time_nanoseconds",
                dimensions: DefaultRecordingClosures.defaultDimensions(observeMetadata),
                preferredDisplayUnit: .nanoseconds
            )
            
            if let sinceDispatchTimeString = relay["sinceDispatchTimeNanoseconds"],
               let sinceDispatchTime = UInt64(sinceDispatchTimeString) {
                timer.recordNanoseconds(DispatchTime.now().uptimeNanoseconds - sinceDispatchTime)
            }
        }
    }
}
