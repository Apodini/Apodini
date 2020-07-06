//
//  TestRESTServer.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini


struct TestServer: Server {    
    @ComponentBuilder var content: some Component {
        Text("Hallo World! 👋")
        Group("swift") {
            Text("Hallo Swift! 💻")
        }
    }
}

TestServer.main()
