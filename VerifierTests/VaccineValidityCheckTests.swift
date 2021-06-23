//
//  VaccineValidityCheckTests.swift
//  VerifierTests
//
//  Created by Davide Aliti on 07/06/21.
//

import XCTest
@testable import VerificaC19
@testable import SwiftDGC
import SwiftyJSON

class VaccineValidityCheckTests: XCTestCase {
    var vaccineValidityCheck: VaccineValidityCheck!
    var hcert: HCert!
    var payload: String!
    var bodyString: String!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        vaccineValidityCheck = VaccineValidityCheck()
        payload = "HC1:6BFOXN%TS3DHPVO13J /G-/2YRVA.Q/R82JD2FCJG96V75DOW%IY17EIHY P8L6IWM$S4U45P84HW6U/4:84LC6 YM::QQHIZC4.OI1RM8ZA.A5:S9MKN4NN3F85QNCY0O%0VZ001HOC9JU0D0HT0HB2PL/IB*09B9LW4T*8+DCMH0LDK2%KI*V AQ2%KYZPQV6YP8722XOE7:8IPC2L4U/6H1D31BLOETI0K/4VMA/.6LOE:/8IL882B+SGK*R3T3+7A.N88J4R$F/MAITHW$P7S3-G9++9-G9+E93ZM$96TV6QRR 1JI7JSTNCA7G6MXYQYYQQKRM64YVQB95326FW4AJOMKMV35U:7-Z7QT499RLHPQ15O+4/Z6E 6U963X7$8Q$HMCP63HU$*GT*Q3-Q4+O7F6E%CN4D74DWZJ$7K+ CZEDB2M$9C1QD7+2K3475J%6VAYCSP0VSUY8WU9SG43A-RALVMO8+-VD2PRPTB7S015SSFW/BE1S1EV*2Q396Q*4TVNAZHJ7N471FPL-CA+2KG-6YPPB7C%40F18N4"
        hcert = HCert(from: payload)
        bodyString = "{\"4\": 1628553600, \"6\": 1620926082, \"1\": \"Ministero della Salute\", \"-260\": {\"1\": {\"ver\": \"1.0.0\", \"dob\": \"1977-06-16\", \"v\": [{\"ma\": \"ORG-100030215\", \"sd\": 2, \"dt\": \"2021-06-08\", \"co\": \"IT\", \"ci\": \"01IT67DA8332EF2C4E6780ABA5DF078A018E#0\", \"mp\": \"EU/1/20/1528\", \"is\": \"Ministero della Salute\", \"tg\": \"840539006\", \"vp\": \"1119349007\", \"dn\": 2}], \"nam\": {\"gnt\": \"MARILU<TERESA\", \"gn\": \"Marilù Teresa\", \"fn\": \"Di Caprio\", \"fnt\": \"DI<CAPRIO\"}}}}"
        LocalData.sharedInstance.settings = []
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        vaccineValidityCheck = nil
        payload = nil
        hcert = nil
        bodyString = nil
        LocalData.sharedInstance.settings = []
    }
    
    func testGetDosesString() {
        let vaccineDoseString = hcert.statement.typeAddon
        let vaccineDosesArray = vaccineValidityCheck.getDosesFromDoseString(from: vaccineDoseString)
        
        XCTAssertEqual(vaccineDosesArray.count, 2)
        XCTAssertEqual(vaccineDosesArray[0], 2)
        XCTAssertEqual(vaccineDosesArray[1], 2)
    }
    
    func testValidVaccineDate() {
        let vaccineSettingStartDay = Setting(name: "vaccine_start_day_complete", type: "EU/1/20/1528", value: "0")
        let vaccineSettingEndDay = Setting(name: "vaccine_end_day_complete", type: "EU/1/20/1528", value: "1")
        LocalData.sharedInstance.addOrUpdateSettings(vaccineSettingStartDay)
        LocalData.sharedInstance.addOrUpdateSettings(vaccineSettingEndDay)
        let todayDate : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateFormatted = dateFormatter.string(from: todayDate)
        bodyString = bodyString.replacingOccurrences(of: "\"dt\": \"2021-06-08\"", with: "\"dt\": \"\(todayDateFormatted)\"")
        hcert.body = JSON(parseJSON: bodyString)[ClaimKey.hCert.rawValue][ClaimKey.euDgcV1.rawValue]
        let isVaccineDateValidResult = vaccineValidityCheck.isVaccineDateValid(hcert)
        
        XCTAssertEqual(isVaccineDateValidResult, .valid)
    }
    
    func testFutureVaccineDate() {
        let vaccineSettingStartDay = Setting(name: "vaccine_start_day_complete", type: "EU/1/20/1528", value: "0")
        let vaccineSettingEndDay = Setting(name: "vaccine_end_day_complete", type: "EU/1/20/1528", value: "1")
        LocalData.sharedInstance.addOrUpdateSettings(vaccineSettingStartDay)
        LocalData.sharedInstance.addOrUpdateSettings(vaccineSettingEndDay)
        let todayDate : Date = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 2, to: todayDate)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let futureDateFormatted = dateFormatter.string(from: futureDate)
        bodyString = bodyString.replacingOccurrences(of: "\"dt\": \"2021-06-08\"", with: "\"dt\": \"\(futureDateFormatted)\"")
        hcert.body = JSON(parseJSON: bodyString)[ClaimKey.hCert.rawValue][ClaimKey.euDgcV1.rawValue]
        let isVaccineDateValidResult = vaccineValidityCheck.isVaccineDateValid(hcert)
        
        XCTAssertEqual(isVaccineDateValidResult, .future)
    }
    
    func testMissingSettingVaccineDate() {
        hcert.body = JSON(parseJSON: bodyString)[ClaimKey.hCert.rawValue][ClaimKey.euDgcV1.rawValue]
        let isVaccineDateValidResultWithNoSettingDate = vaccineValidityCheck.isVaccineDateValid(hcert)
        
        XCTAssertTrue(isVaccineDateValidResultWithNoSettingDate == .notValid)
        
        let vaccineSettingStartDay = Setting(name: "vaccine_start_day_complete", type: "EU/1/20/155288", value: "0")
        let vaccineSettingEndDay = Setting(name: "vaccine_end_day_complete", type: "EU/1/20/155288", value: "1")
        LocalData.sharedInstance.addOrUpdateSettings(vaccineSettingStartDay)
        LocalData.sharedInstance.addOrUpdateSettings(vaccineSettingEndDay)
        let isVaccineDateValidResultWithWrongVaccineType = vaccineValidityCheck.isVaccineDateValid(hcert)
        
        XCTAssertEqual(isVaccineDateValidResultWithWrongVaccineType, .notValid)
    }

}
