//
//  Application+FCM.swift
//  
//
//  Created by Tim Gymnich on 30.12.20.
//

import FCM

extension Application {
    public var fcm: FCM {
        .init(app: self)
    }
}

extension FCM {
    init(app: Application) {
        self.init(application: app.vapor.app)
    }
}
