//
//  VaccineValidityCheck.swift
//  Verifier
//
//  Created by Davide Aliti on 21/05/21.
//

import Foundation
import SwiftDGC

struct VaccineValidityCheck {
    
    func isVaccineDateValid(_ hcert: HCert) -> Status {
        guard let currentDoses = hcert.currentDosesNumber else { return .notValid }
        guard let totalDoses = hcert.totalDosesNumber else { return .notValid }
        guard currentDoses <= totalDoses else { return .notValid }
        let isLastDose = currentDoses == totalDoses
        
        guard let product = hcert.medicalProduct else { return .notValid }
        guard isValid(for: product) else { return .notValid }
        
        guard let start = getStartDays(for: product, isLastDose) else { return .notValid }
        guard let end = getEndDays(for: product, isLastDose) else { return .notValid }
        
        guard let dateString = hcert.vaccineDate else { return .notValid }
        guard let date = dateString.toVaccineDate else { return .notValid }
        guard let validityStart = date.add(start, ofType: .day) else { return .notValid }
        guard let validityEnd = date.add(end, ofType: .day) else { return .notValid }

        guard let currentDate = Date.startOfDay else { return .notValid }
        
        return Validator.validate(currentDate, from: validityStart, to: validityEnd)
    }
    
    private func isValid(for medicalProduct: String) -> Bool {
        // Vaccine code not included in settings -> not a valid vaccine for Italy
        let name = "vaccine_end_day_complete"
        return getProduct(from: name, type: medicalProduct) != nil
    }
     
    private func getStartDays(for medicalProduct: String, _ isLastDose: Bool) -> Int? {
        let name = isLastDose ? "vaccine_start_day_complete" : "vaccine_start_day_not_complete"
        return getProduct(from: name, type: medicalProduct)?.intValue
    }
    
    private func getEndDays(for medicalProduct: String, _ isLastDose: Bool) -> Int? {
        let name = isLastDose ? "vaccine_end_day_complete" : "vaccine_end_day_not_complete"
        return getProduct(from: name, type: medicalProduct)?.intValue
    }
    
    private func getProduct(from name: String, type: String) -> String? {
        return LocalData.getSetting(from: name, type: type)
    }
    
}
