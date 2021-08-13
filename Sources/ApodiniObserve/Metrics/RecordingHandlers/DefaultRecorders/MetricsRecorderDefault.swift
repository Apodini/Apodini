//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

public struct MetricsRecorderDefault: MetricsRecorder {
    public typealias Key = String
    public typealias Value = String
    
    public var before: [BeforeRecordingClosure]
    
    public var after: [AfterRecordingClosure]
    
    public var afterException: [AfterExceptionRecordingClosure]
    
    public init(before: [BeforeRecordingClosure], after: [AfterRecordingClosure], afterException: [AfterExceptionRecordingClosure]) {
        self.before = before
        self.after = after
        self.afterException = afterException
    }
}
