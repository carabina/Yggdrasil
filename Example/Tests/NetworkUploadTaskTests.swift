//
//  NetworkUploadTaskTests.swift
//  Yggdrasil_Tests
//
//  Created by Thomas Sempf on 2018-03-21.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Yggdrasil

class NetworkUploadTaskTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private struct TestPostRequest: Yggdrasil.Request {
        var endpoint: Endpoint { return NetworkEndpoint(baseUrl: "https://httpbin.org", path: "/post", method: .post) }
        var preconditions: [PreconditionValidation] = []
        var responseValidations: [ResponseValidation] = []
        var retryCount: Int = 0
        var headers: [String : String] = ["Test": "Test"]
        
        init(preconditions: [PreconditionValidation] = [], responseValidations: [ResponseValidation] = [], retryCount: Int = 0) {
            self.preconditions = preconditions
            self.responseValidations = responseValidations
            self.retryCount = retryCount
        }
    }
    
    func testCreationOfUploadRequest() {
        let request = TestPostRequest()
        let uploadTask = UploadTask<Data>(request: request, dataToUpload: .data("FooBar".data(using: .utf8)!))
        
        do {
            let uploadRequest = try uploadTask.createUploadRequest()
            let fullRequestURL = try request.fullURL.asURL()
            
            XCTAssert(uploadRequest.request?.url == fullRequestURL)
            XCTAssert(uploadRequest.request?.httpMethod == request.endpoint.method.rawValue)
            XCTAssert(uploadRequest.request?.allHTTPHeaderFields == request.headers)
        } catch {
            XCTFail()
        }
    }
    
    func testProgressReportingIsTriggered() {
        let request = TestPostRequest()
        let uploadTask = UploadTask<Data>(request: request, dataToUpload: .data("FooBar".data(using: .utf8)!))
        let finishedExpectation = expectation(description: "Finished")
        
        DispatchQueue.global().async {
            do {
                try uploadTask.await()
                
                XCTAssert(uploadTask.progress.completedUnitCount == 1)
                XCTAssert(uploadTask.progress.fractionCompleted == 1.0)
                
                finishedExpectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSuccessCase() {
        let request = TestPostRequest()
        let uploadTask = UploadTask<Data>(request: request, dataToUpload: .data("FooBar".data(using: .utf8)!))
        let finishedExpectation = expectation(description: "Finished")
        
        uploadTask.async { (result) in
            defer { finishedExpectation.fulfill() }
            
            guard case .success = result else {
                XCTFail("Wrong result")
                return
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFailureCase() {
        let uploadTask = UploadTask<Data>(url: " ", dataToUpload: .data("FooBar".data(using: .utf8)!))
        let finishedExpectation = expectation(description: "Finished")
        
        uploadTask.async(completion: { (result) in
            defer { finishedExpectation.fulfill() }
            
            guard case let .failure(error) = result else {
                XCTFail("Wrong result")
                return
            }
            
            XCTAssert(error.localizedDescription == "URL is not valid: ")
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
