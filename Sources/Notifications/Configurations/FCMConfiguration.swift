import Foundation
import FCM
import Apodini

public struct FCMConfiguration: Configuration {
    let filePath: String
    
    public init(_ filePath: String) {
        self.filePath = filePath
    }
    
    public func configure(_ app: Application) {
        let serviceAccount = readJSON()
        app.fcm.configuration = .init(email: serviceAccount.clientEmail,
                                      projectId: serviceAccount.projectId,
                                      key: serviceAccount.privateKey,
                                      serverKey: serviceAccount.serverKey,
                                      senderId: serviceAccount.senderId)
    }
    
    private func readJSON() -> ServiceAccount {
        let fileManger = FileManager.default
        guard let data = fileManger.contents(atPath: filePath) else {
            fatalError("FCM file doesn't exist at path: \(filePath)")
        }
        guard let serviceAccount = try? JSONDecoder().decode(ServiceAccount.self, from: data) else {
            fatalError("FCM unable to decode serviceAccount from file located at: \(filePath)")
        }
        
        return serviceAccount
    }
}


struct ServiceAccount: Codable {
    let projectId: String
    let privateKey: String
    let clientEmail: String
    let serverKey: String?
    let senderId: String?
    
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case serverKey = "server_key"
        case senderId = "sender_id"
    }
}
