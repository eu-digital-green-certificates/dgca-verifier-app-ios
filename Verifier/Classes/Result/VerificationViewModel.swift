/*
 *  license-start
 *  
 *  Copyright (C) 2021 Ministero della Salute and all other contributors
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
*/

//
//  ResultViewModel.swift
//  verifier-ios
//
//

import Foundation
import SwiftDGC

enum Status {
    case valid
    case expired
    case future
    case notValid
    case invalidQR
}

func validateWithMedicalRules(_ hcert: HCert) -> Status {
    switch hcert.type {
    case .test:
        let testValidityCheck = TestValidityCheck()
        return testValidityCheck.isTestValid(hcert)
    case .vaccine:
        let vaccineValidityCheck = VaccineValidityCheck()
        return vaccineValidityCheck.isVaccineDateValid(hcert)
    case .recovery:
        let recoveryValidityCheck = RecoveryValidityCheck()
        return recoveryValidityCheck.isRecoveryValid(hcert)
    }
}

extension HCert {
    private var listItems: [InfoSection]? {
        self.info.filter { !$0.isPrivate }
    }
    var standardizedFirstName: String? {
        return listItems?.filter { $0.header == l10n("header.std-gn")}.first?.content
    }
    var standardizedLastName: String? {
        return listItems?.filter { $0.header == l10n("header.std-fn")}.first?.content
    }
    
    var firstName: String {
        return self.body["nam"]["gn"].string ?? ""
    }
    
    var lastName: String {
        return self.body["nam"]["fn"].string ?? ""
    }
}

class VerificationViewModel {

    var status: Status
    var hCert: HCert?
        
    init(qrCodeText: String) {
        hCert = HCert(from: qrCodeText)
        
        if hCert == nil {
            status = .invalidQR
        }
        else {
            if hCert!.isValid {
                status = validateWithMedicalRules(hCert!)
            }
            else {
                status = .invalidQR
            }
        }
    }
    
    var imageName: String {
        return status == .valid ? "icon_checkmark-filled" : "icon_misuse"
    }
    var title: String {
        return status == .valid ? "result.valid.title".localized : "result.invalid.title".localized
    }
    var description: String {
        switch status {
        case .valid:
            return "result.valid.description".localized
        case .expired:
            return "result.expired.description".localized
        case .future:
            return "result.future.description".localized
        case .invalidQR:
            return "result.invalidQR.description".localized
        case .notValid:
            return "result.notValid.description".localized
        }
    }
    var rescanButtonTitle: String {
        return status == .valid ? "result.nextScan".localized : "result.rescan".localized
    }
    
    var resultItems: [ResultItem]? {
        if status == .invalidQR {
            return nil
        }
        
        let firstName = hCert?.firstName ?? ""
        let lastName = hCert?.lastName ?? ""
        
        return [
            ResultItem(title: lastName + " " + firstName, subtitle: "", imageName: "icon_user"),
            ResultItem(title: "result.bithdate".localized, subtitle: birthDateString, imageName: "icon_calendar")
        ]
    }
    
    var birthDateString: String? {
        guard let dateOfBirth = hCert?.dateOfBirth else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateOfBirth) else { return nil }
        let italianDateFormatter = DateFormatter()
        italianDateFormatter.dateFormat = "dd/MM/yyyy"
        return italianDateFormatter.string(from: date)
    }
}
