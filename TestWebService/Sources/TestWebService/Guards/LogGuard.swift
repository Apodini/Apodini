//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini
import Logging

struct LogGuard: SyncGuard {
    private let message: String
    
    @Environment(\.logger) var logger: Logger
    
    
    init(_ message: String = "LogGuard 👋") {
        self.message = message
    }
    
    
    func check() {
        logger.info("\(message)")
    }
}
