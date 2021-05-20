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
    case invalidQR
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
                status = .valid
            }
//            waiting for medical rules
//            else if !validateMedicalRules(hCert!) {
//                status = .expired
//            }
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
        return status == .valid ? "result.valid.description".localized : (status == .expired ? "result.expired.description".localized : "result.invalid.description".localized)
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
