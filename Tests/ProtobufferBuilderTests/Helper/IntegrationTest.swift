import XCTest
import Apodini

#if os(Linux)
import FoundationNetworking
#endif

struct IntegrationTest<S: WebService> {
    let url: String
    let expectedResponse: String
    
    func execute(`in` testCase: XCTestCase) {
        #if os(Linux)
        return
        #endif
        
        guard let url = URL(string: url) else {
            XCTAssertNotNil(nil, "Url was nil")
            return
        }
        
        DispatchQueue.global().async {
            S.main()
        }
        
        let expectation = XCTestExpectation()
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
            guard let data = data,
                  let string = String(data: data, encoding: .utf8) else {
                XCTAssertNotNil(nil, "Data or string was nil")
                return
            }
            
            XCTAssertEqual(string, expectedResponse)
            expectation.fulfill()
        })
        
        task.resume()
        
        testCase.wait(for: [expectation], timeout: 10.0)
    }
}
