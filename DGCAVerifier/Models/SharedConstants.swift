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
//  SharedConstants.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 05.11.2021.
//  
        

import Foundation

enum SharedConstants {
    static let expiredDataInterval: TimeInterval = 12.0 * 60 * 60
    static let dataStorageName = "secure_storage"
    
    static let linkToOpenGitHubSource = "https://github.com/eu-digital-green-certificates"
    static let linkToOopenEuCertDoc = "https://ec.europa.eu/health/ehealth/covid-19_en"
    static let revocationServiceBase = "https://dgca-revocation-service-eu-test.cfapps.eu10.hana.ondemand.com"
}
