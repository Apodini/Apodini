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
        app.fcm.configuration = .init(email: serviceAccount.client_email,
                                      projectId: serviceAccount.project_id,
                                      key: serviceAccount.private_key,
                                      serverKey: serviceAccount.server_key,
                                      senderId: serviceAccount.sender_id)
        NotificationCenter.shared.setup(app)
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

// swiftlint:disable identifier_name
struct ServiceAccount: Codable {
    let project_id: String //NOSONAR
    let private_key: String //NOSONAR
    let client_email: String //NOSONAR
    let server_key: String? //NOSONAR
    let sender_id: String? //NOSONAR
}
// swiftlint:enable identifier_name
