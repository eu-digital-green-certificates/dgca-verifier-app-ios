//
//  HomeViewModelTests.swift
//  VerifierTests
//
//  Created by Davide Aliti on 07/06/21.
//

import XCTest
@testable import VerificaC19

class HomeViewModelTests: XCTestCase {
    
    var homeViewModel: HomeViewModel!
    var localData: LocalData!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        homeViewModel = HomeViewModel()
        localData = LocalData(encodedPublicKeys: [:], resumeToken: nil, lastFetchRaw: nil, settings: [])
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        homeViewModel = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testVersionOutdated() {
        let setting = Setting(name: "ios", type: "APP_MIN_VERSION", value: "0.0.0")
        LocalData.sharedInstance.settings.append(setting)
        
//        XCTAssertFalse(homeViewModel.isCurrentVersionOutdated())
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
