//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Logging

extension Logger: KnowledgeSource {
    public static var preference: LocationPreference { .global }
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self = blackboard[Application.self].logger
    }
}
