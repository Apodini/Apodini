//
//  MockExporterRequest.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import ApodiniExtension


#if DEBUG
public struct MockExporterRequest: ExporterRequest, WithEventLoop {
    public let eventLoop: EventLoop
    private let doNotReduceRequest: Bool
    let mockableParameters: [String: MockableParameter]
    
    
    private init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, mockableParameters: [String: MockableParameter]) {
        self.eventLoop = eventLoop
        self.mockableParameters = mockableParameters
        self.doNotReduceRequest = doNotReduceRequest
    }
    
    init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, mockableParameters: [MockableParameter] = []) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: Dictionary(uniqueKeysWithValues: mockableParameters.map { ($0.id, $0) }))
    }
    
    
    public func reduce(to new: MockExporterRequest) -> MockExporterRequest {
        if new.doNotReduceRequest {
            return new
        } else {
            return MockExporterRequest(on: new.eventLoop, mockableParameters: self.mockableParameters.merging(new.mockableParameters) { $1 })
        }
    }
}
#endif
