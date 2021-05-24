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
        case .invalidQR:
            return "result.invalidQR.description".localized
        case .notValid:
            return "result.notValid.description".localized
        }
    }
    var rescanButtonTitle: String {
        return status == .valid ? "result.nextScan".localized : "result.rescan".localized
    }
    
    var listItems: [InfoSection]? {
            hCert?.info.filter { !$0.isPrivate }
    }
    
    var resultItems: [ResultItem]? {
        if status == .invalidQR {
            return nil
        }
        
        let standardizedFirstName = listItems?.filter { $0.header == l10n("header.std-fn")}.first?.content ?? ""
        let standardizedLastName = listItems?.filter { $0.header == l10n("header.std-gn")}.first?.content ?? ""
        
        return [
            ResultItem(title: hCert?.fullName, subtitle: standardizedFirstName + " " + standardizedLastName, imageName: "icon_user"),
            ResultItem(title: "result.bithdate".localized, subtitle: birthDateString, imageName: "icon_calendar")
        ]
    }
    
    var birthDateString: String? {
        guard let dateOfBirth = hCert?.dateOfBirth else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: dateOfBirth)
    }
}
