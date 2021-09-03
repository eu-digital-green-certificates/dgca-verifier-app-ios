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
//  DebugModeManager.swift
//  DGCAVerifier
//  
//  Created by Illia Vlasov on 03.09.2021.
//  
        
import SwiftDGC
import UIKit
import Foundation

class DebugModeManager {
    func prepareZipData(_ cert: HCert?, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        do {
            try generateVersion()
            try generateReadme()
        } catch {
            completionHandler(.failure(error))
        }
        
    }
    
    private func generateVersion() throws {
        do {
            try writeToFile(filename: "VERSION.txt",text: "1.00")
        } catch {
            throw error
        }
    }
    
    private func generateReadme() throws {
        do {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
            
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let timestamp = formatter.string(from: today)
            let readmeText = """
                \(timestamp)
                \(appName)
                \(version)
                """
            try writeToFile(filename: "README.txt",text: readmeText)
        } catch {
            throw error
        }
    }
    
    private func generatePayloadSHABin(_ certificate: HCert) throws {
        let payloadSHABin = certificate.payloadString
        try writeToFile(filename: "", text: payloadSHABin)
    }
}

extension DebugModeManager {
    fileprivate func writeToFile(filename: String,text: String) throws {

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(filename)

            do {
                try text.write(to: fileURL, atomically: true, encoding: .ascii)
            }
            catch {
                throw error
            }
        }
    }
}
