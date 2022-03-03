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
//  CertificateValidator+Revocation.swift
//  DGCAVerifier
//
//  Created by Igor Khomiak on 20.02.2022.
//
        

import UIKit
import SwiftDGC
import DGCBloomFilter


extension CertificateValidator {

    var revocationManager: RevocationManager {
        return RevocationManager()
    }

    func validateRevocation() -> ValidityState {
        let kidConverted = Helper.convertToBase64url(base64: certificate.kidStr)
        
        if let revocation = revocationManager.loadRevocation(kid: kidConverted),
            let revocMode = RevocationMode(rawValue: revocation.mode!),
            let hashTypes = revocation.hashTypes {
            let arrayHashTypes = hashTypes.split(separator: ",")

            if arrayHashTypes.contains("SIGNATURE"), let hashData = certificate.signatureHash {
                let lookup: CertLookUp = certificate.lookUp(mode: revocMode, hash: hashData)
                let result = searchInDatabase(lookUp: lookup, hash: hashData)
                if result == true {
                    return ValidityState.revocatedState
                }
            }
            
            if arrayHashTypes.contains("UCI"), let hashData = certificate.uvciHash {
                let lookup: CertLookUp = certificate.lookUp(mode: revocMode, hash: hashData)
                let result = searchInDatabase(lookUp: lookup, hash: hashData)
                if result == true {
                    return ValidityState.revocatedState
                }
            }
            
            if arrayHashTypes.contains("COUNTRYCODEUCI"), let hashData = certificate.countryCodeUvciHash {
                let lookup: CertLookUp = certificate.lookUp(mode: revocMode, hash: hashData)
                let result = searchInDatabase(lookUp: lookup, hash: hashData)
                if result == true {
                    return ValidityState.revocatedState
                }
            }
       }
        return ValidityState.validState
    }

    private func searchInDatabase(lookUp: CertLookUp, hash: Data) -> Bool {
        let slices = revocationManager.loadSlices(kid: lookUp.kid, x: lookUp.x, y: lookUp.y, section: lookUp.section)
        for slice in slices ?? [] {
            guard let sliceData = slice.value(forKey: "hashData") as? Data, let sliceType = slice.type else { continue }
            if sliceType.lowercased().contains("bloom")  {
                let filter = BloomFilter(data: sliceData)
                let result = filter.mightContain(element: hash)
                if result {
                    return true
                }
            } else {
                //TODO process hash type
            }
        }
        return false
    }
}
