//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIOHTTP2

extension HTTP2Frame.FramePayload: CustomStringConvertible {
    public var description: String {
        switch self {
        case .data(let data):
            if case .byteBuffer(let buffer) = data.data {
                let str = buffer.getString(at: 0, length: buffer.readableBytes) ?? "could not get String from buffer"
                return ".data: \(NSString(string: str))"
            } else {
                return ".data: other"
            }
        default:
            return "other frame"
        }
    }
}
