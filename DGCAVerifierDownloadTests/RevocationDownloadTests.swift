//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  RevocationDownloadTests.swift
//  RevocationDownloadTests
//  
//  Created by Denis Melenevsky on 22.02.2022.
//  
        

import XCTest
@testable import DGCAVerifier
import DCCInspection

let mockRevocationListsResponse = """
    [{\"kid\":\"9cWXDDA52FQ=\",\"mode\":\"POINT\",\"hashTypes\":[\"SIGNATURE\"],\"expires\":\"2023-03-01T11:00:00Z\",\"lastUpdated\":\"2022-03-04T16:08:49Z\"},{\"kid\":\"GSXuNoyWGYo=\",\"mode\":\"POINT\",\"hashTypes\":[\"UCI\"],\"expires\":\"2023-11-27T10:15:14Z\",\"lastUpdated\":\"2022-03-09T11:29:40Z\"}]
    """

let mockRevocationListsUpdateResponse = """
    [{\"kid\":\"9cWXDDA52FQ=\",\"mode\":\"POINT\",\"hashTypes\":[\"SIGNATURE\"],\"expires\":\"2023-03-01T11:00:00Z\",\"lastUpdated\":\"2022-03-10T16:08:49Z\"},{\"kid\":\"GSXuNoyWGYo=\",\"mode\":\"POINT\",\"hashTypes\":[\"UCI\"],\"expires\":\"2023-11-27T10:15:14Z\",\"lastUpdated\":\"2022-03-11T11:29:40Z\"}]
    """

let mockRevocationListsDeleteResponse = """
    [{\"kid\":\"9cWXDDA52FQ=\",\"mode\":\"POINT\",\"hashTypes\":[\"SIGNATURE\"],\"expires\":\"2023-03-01T11:00:00Z\",\"lastUpdated\":\"2022-03-10T16:08:49Z\"},{\"kid\":\"GSXuNoyWGYo=\",\"mode\":\"POINT\",\"hashTypes\":[\"UCI\"],\"expires\":\"2023-11-27T10:15:14Z\",\"lastUpdated\":\"2022-03-11T11:29:40Z\"}]
    """

let mockRevocationPartitionsResponse = """
    [{\"kid\":\"GSXuNoyWGYo=\",\"id\":null,\"x\":null,\"y\":null,\"lastUpdated\":\"2022-03-09T11:29:40.029718Z\",\"expired\":\"2023-11-27T10:15:00Z\",\"chunks\":{\"2\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"0132815288af51fcfc709f422aee353687654513e4b105fdc8f6166e2df90bbb\"}},\"3\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"24352fcfac12fa8077f074fe6ba1814d09383db29899a1120ca6e587a0d7399d\"}},\"5\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"9e7556604c1774b2e5db4721a7a8ca4fe8c1aade97ad6386a0144218cc3bba56\"}},\"6\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"482dd47c5f344538302328c57e7dd211b27274a264d830f98a0d02d5bb163fc3\"}},\"f\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"75572ebd77dc4b07f49479b69aa7400c4a73472fd7b516dc1a10aa51dad86ea3\"}},\"8\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"1e84743ec149ed4c5f02abe27dab0ef0bade3e8882a8d2907419b252c7a768b0\"}}}}]
    """

let mockRevocationPartitionsUpdateResponse = """
    [{\"kid\":\"GSXuNoyWGYo=\",\"id\":null,\"x\":null,\"y\":null,\"lastUpdated\":\"2022-03-11T11:29:40.029718Z\",\"expired\":\"2023-11-27T10:15:00Z\",\"chunks\":{\"2\":{\"2023-11-29T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.1\",\"hash\":\"0132815288af51fcfc709f422aee353687654513e4b105fdc8f6166e2df90bbb\"}},\"3\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"24352fcfac12fa8077f074fe6ba1814d09383db29899a1120ca6e587a0d7399d\"}},\"5\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"9e7556604c1774b2e5db4721a7a8ca4fe8c1aade97ad6386a0144218cc3bba56\"}},\"6\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"482dd47c5f344538302328c57e7dd211b27274a264d830f98a0d02d5bb163fc3\"}},\"b\":{\"2023-11-29T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"2.1\",\"hash\":\"0132815288af51fcfc709f422aee353687654513e4b105fdc8f6166e2df90bbc\"}},\"f\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"75572ebd77dc4b07f49479b69aa7400c4a73472fd7b516dc1a10aa51dad86ea3\"}},\"8\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"1e84743ec149ed4c5f02abe27dab0ef0bade3e8882a8d2907419b252c7a768b0\"}}}}]
    """

let mockRevocationPartitionsDeleteResponse = """
    [{\"kid\":\"GSXuNoyWGYo=\",\"id\":null,\"x\":null,\"y\":null,\"lastUpdated\":\"2022-03-09T11:29:40.029718Z\",\"expired\":\"2023-11-27T10:15:00Z\",\"chunks\":{\"2\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"0132815288af51fcfc709f422aee353687654513e4b105fdc8f6166e2df90bbb\"}},\"3\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"24352fcfac12fa8077f074fe6ba1814d09383db29899a1120ca6e587a0d7399d\"}},\"5\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"9e7556604c1774b2e5db4721a7a8ca4fe8c1aade97ad6386a0144218cc3bba56\"}},\"6\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"482dd47c5f344538302328c57e7dd211b27274a264d830f98a0d02d5bb163fc3\"}},\"f\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"75572ebd77dc4b07f49479b69aa7400c4a73472fd7b516dc1a10aa51dad86ea3\"}},\"8\":{\"2023-11-27T10:15:00Z\":{\"type\":\"BLOOMFILTER\",\"version\":\"1.0\",\"hash\":\"1e84743ec149ed4c5f02abe27dab0ef0bade3e8882a8d2907419b252c7a768b0\"}}}}]
    """

let testKid = "GSXuNoyWGYo"
let testHashId = "0132815288af51fcfc709f422aee353687654513e4b105fdc8f6166e2df90bbb"
let updatedTestHashId = "0132815288af51fcfc709f422aee353687654513e4b105fdc8f6166e2df90bbc"

class MockRevocationService: RevocationServiceProtocol {
    enum TestMode {
        case new
        case update
        case delete
    }
    
    var testMode: TestMode = .new
    
    func getRevocationLists(completion: @escaping RevocationListCompletion) {
        let responseString: String
        switch testMode {
        case .new:
            responseString = mockRevocationListsResponse
        case .update:
            responseString = mockRevocationListsUpdateResponse
        case .delete:
            responseString = mockRevocationListsDeleteResponse
        }
        
        guard let data = responseString.data(using: .utf8) else {
            completion(nil, nil, .nodata)
            return
        }
        
        do {
            let responseModels = try JSONDecoder().decode([RevocationModel].self, from: data)
            completion(responseModels, "", nil)
        } catch {
            completion(nil, nil, .nodata)
        }
    }
    
    func getRevocationPartitions(for kid: String, completion: @escaping PartitionListCompletion) {
        let responseString: String
        switch testMode {
        case .new:
            responseString = mockRevocationPartitionsResponse
        case .update:
            responseString = mockRevocationPartitionsUpdateResponse
        case .delete:
            responseString = mockRevocationPartitionsDeleteResponse
        }
        
        guard let data = responseString.data(using: .utf8) else {
            completion(nil, nil, .nodata)
            return
        }
        
        do {
            let responseModels = try JSONDecoder().decode([PartitionModel].self, from: data)
            completion(responseModels, "", nil)
        } catch {
            completion(nil, nil, .nodata)
        }
    }
    
    func getRevocationPartitions(for kid: String, id: String, completion: @escaping PartitionListCompletion) {
        print(kid)
    }
    
    func getRevocationPartitionChunks(for kid: String, id: String, cids: [String]?, completion: @escaping ZIPDataTaskCompletion) {
        let gzFilename: String
        switch testMode {
        case .new:
            gzFilename = "mockRevocationPartitionChunks"
        case .update:
            gzFilename = "mockRevocationPartitionChunksUpdate"
        case .delete:
            gzFilename = "mockRevocationPartitionChunksUpdate"
        }
        
        guard let gzUrl = Bundle(for: type(of: self)).url(forResource: gzFilename, withExtension: "tar.gz") else {
            completion(nil, .nodata)
            return
        }
              
        do {
            let data = try Data(contentsOf: gzUrl)
            completion(data, nil)
        } catch {
            completion(nil, .nodata)
        }
    }
    
    func getRevocationPartitionChunk(for kid: String, id: String, cid: String, completion: @escaping ZIPDataTaskCompletion) {
        
    }
    
    func getRevocationPartitionChunkSlice(for kid: String, id: String, cid: String, sids: [String]?, completion: @escaping ZIPDataTaskCompletion) {
        
    }
    
    func getRevocationPartitionChunkSliceSingle(for kid: String, id: String, cid: String, sid: String, completion: @escaping ZIPDataTaskCompletion) {
        
    }
    
    
}

class RevocationDownloadTests: XCTestCase {
    let service = MockRevocationService()
    lazy var worker = RevocationWorker(service: service)

    override func setUpWithError() throws {
        worker.revocationCoreDataManager.clearAllData()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDownload() throws {
        
        let expectation = XCTestExpectation(description: "Revocations saved")

        service.testMode = .new
        worker.processReloadRevocations { revocationError in
            let revocations = self.worker.revocationCoreDataManager.currentRevocations()
            
            XCTAssert(revocations.count == 2)
            
            let kids = revocations.map { $0.kid ?? "" }
            
            XCTAssertEqual(kids, ["9cWXDDA52FQ", "GSXuNoyWGYo"])
                        
            let slices = self.worker.revocationCoreDataManager.loadSlices(kid: testKid, x: "null", y: "null", section: "2")
            
            XCTAssertNotNil(slices)
            XCTAssert(slices!.count == 1)
            
            let slice = slices!.last!
            XCTAssertNotNil(slice.hashID)
            XCTAssertEqual(slice.hashID!, testHashId)
            XCTAssertNotNil(slice.hashData)
            
            do {
                let testHashDataUrl = Bundle(for: type(of: self)).url(forResource: "testHash", withExtension: nil)
                let testHashData = try Data(contentsOf: testHashDataUrl!)
                
                XCTAssertEqual(slice.hashData, testHashData)
            
                expectation.fulfill()
            } catch {
                print(error)
            }
        }
        
        let waiterResult = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(waiterResult, .completed)
    }
    
    func testUpdate() {
        let newDownloadExpectation = XCTestExpectation(description: "New revocations downloaded")

        service.testMode = .new
        worker.processReloadRevocations { revocationError in
            if revocationError == nil {
                newDownloadExpectation.fulfill()
            }
        }
        
        let newDownloadResult = XCTWaiter.wait(for: [newDownloadExpectation], timeout: 2.0)
//        guard newDownloadResult == .completed else {
//            return
//        }
        
        let updateExpectation = XCTestExpectation(description: "Revocations updated")

        service.testMode = .update
        worker.processReloadRevocations { revocationError in
            if revocationError == nil {
                updateExpectation.fulfill()
            }
        }
        
        let updateResult = XCTWaiter.wait(for: [updateExpectation], timeout: 2.0)
        if updateResult == .completed {
            let slices = self.worker.revocationCoreDataManager.loadSlices(kid: testKid, x: "null", y: "null", section: "2")
            
            XCTAssertNotNil(slices)
            XCTAssert(slices!.count == 1)
            
            let slice = slices!.last!
            XCTAssertNotNil(slice.hashID)
            XCTAssertEqual(slice.hashID!, updatedTestHashId)
            XCTAssertNotNil(slice.hashData)
            
            do {
                let testHashDataUrl = Bundle(for: type(of: self)).url(forResource: "updatedTestHash", withExtension: nil)
                let testHashData = try Data(contentsOf: testHashDataUrl!)
                
                XCTAssertEqual(slice.hashData, testHashData)
            } catch {
                print(error)
            }
        }
    }
}
