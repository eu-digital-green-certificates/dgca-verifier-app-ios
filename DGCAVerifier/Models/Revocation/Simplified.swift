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
//  Simplified.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 17.03.2022.
//  
        

import Foundation
import SwiftDGC

struct SimpleRevocation {
    let kid: String
    let mode: String
    let hashTypes: String
    let expires: Date
    let lastUpdated: Date
    
    var lastUpdatedString: String {
        return lastUpdated.dateOffsetString
    }
}

struct SimpleSlice {
    let kid: String
    let partID: String
    let chunkID: String
    let version: String
    let hashID: String
    let expiredDate: Date
    var hashData: Data?
    let type: String
    
    var dateString: String?
}
