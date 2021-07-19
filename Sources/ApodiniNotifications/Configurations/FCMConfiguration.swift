//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import FCM
import Apodini


public struct FirebaseConfiguration: Configuration {
    let configuration: FCMConfiguration
    
    
    public init(_ filePath: URL) {
        guard let json = try? String(contentsOf: filePath) else {
            fatalError("Could not read the FCMConfiguration from the file located at \(filePath)")
        }
        self.configuration = FCMConfiguration(fromJSON: json)
    }
    
    
    public func configure(_ app: Application) {
        app.fcm.configuration = configuration
    }
}
