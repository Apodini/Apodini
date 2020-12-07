import XCTest
import Apodini

struct IntegrationTest<S: WebService> {
    let url: String
    let expectedResponse: String
    
    func execute(`in` testCase: XCTestCase) {
        guard let url = URL(string: url) else {
            XCTAssertNotNil(nil, "Url was nil")
            return
        }
        
        DispatchQueue.global().async {
            S.main()
        }
        
        let expectation = XCTestExpectation()
        
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
            guard let data = data,
                  let string = String(data: data, encoding: .utf8) else {
                XCTAssertNotNil(nil, "Data or string was nil")
                return
            }
            
            XCTAssertEqual(string, expectedResponse)
            expectation.fulfill()
        }).resume()
        
        testCase.wait(for: [expectation], timeout: 1.0)
    }
}
