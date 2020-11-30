//
//  File.swift
//  
//
//  Created by Alexander Collins on 30.11.20.
//

import FCM
import Vapor


public struct FCMConfiguration: Configuration {
    let filePath: String
    
    public init(_ filePath: String) {
        self.filePath = filePath
    }
    
    public func configure(_ app: Application) {
        let serviceAccount = readJSON()
        app.fcm.configuration = .init(email: serviceAccount.client_email,
                                      projectId: serviceAccount.project_id,
                                      key: serviceAccount.private_key,
                                      serverKey: serviceAccount.server_key,
                                      senderId: serviceAccount.sender_id)
    }
    
    private func readJSON() -> ServiceAccount {
        let fileManger = FileManager.default
        guard let data = fileManger.contents(atPath: filePath) else {
            fatalError("FCM file doesn't exists at path: \(filePath)")
        }
        guard let serviceAccount = try? JSONDecoder().decode(ServiceAccount.self, from: data) else {
            fatalError("FCM unable to decode serviceAccount from file located at: \(filePath)")
        }
        
        return serviceAccount
    }
}

struct ServiceAccount: Codable {
    let project_id: String
    let private_key: String
    let client_email: String
    let server_key: String?
    let sender_id: String?
}
