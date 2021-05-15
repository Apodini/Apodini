//
//  MockExporterRequest.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
public struct MockExporterRequest: ExporterRequest, WithEventLoop {
    public let eventLoop: EventLoop
    let doNotReduceRequest: Bool
    let mockableParameters: [String: MockableParameter]
    
    
    private init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, mockableParameters: [String: MockableParameter]) {
        self.eventLoop = eventLoop
        self.mockableParameters = mockableParameters
        self.doNotReduceRequest = doNotReduceRequest
    }
    
    init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, mockableParameters: [MockableParameter] = []) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: Dictionary(uniqueKeysWithValues: mockableParameters.map { ($0.id, $0) }))
    }
    
    init<Value: Decodable>(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, _ values: Value...) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: values.map { UnnamedParameter($0) })
    }
    
    init(on eventLoop: EventLoop, doNotReduceRequest: Bool = false, @MockableParameterBuilder mockableParameters: () -> ([MockableParameter])) {
        self.init(on: eventLoop, doNotReduceRequest: doNotReduceRequest, mockableParameters: mockableParameters())
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
