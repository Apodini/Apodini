//
//  Application+FCM.swift
//  
//
//  Created by Tim Gymnich on 30.12.20.
//

import FCM

extension Application {
    /// Firebase Cloud Messaging.
    public var fcm: FCM {
        // Stores FCM in apo storage otherwise a warning will be logged.
        if let fcm = self.storage[ConfigurationKey.self] {
            return fcm
        }
        let fcm = FCM(app: self)
        self.storage[ConfigurationKey.self] = fcm
        
        return fcm
    }
    
    struct ConfigurationKey: StorageKey {
        typealias Value = FCM
    }
}

extension FCM {
    init(app: Application) {
        self.init(application: app.vapor.app)
    }
}
