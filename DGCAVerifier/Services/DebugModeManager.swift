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
import SwiftCBOR

class DebugModeManager {
  func prepareZipData(_ cert: HCert, completionHandler: @escaping (Result<Data, Error>) -> Void) {
    var data : Data = Data(count: 32)
    
    do {
      try generateVersion()
      try generateReadme()
      try generatePayloadSHABin(cert)
      try generatePayloadSHATxt(cert)
      try generateQRBase64(cert)
      try generatePayloadJson(cert)
      try generateQRSHABin(cert)
      try generateQRSHATxt(cert)
      try generateQRImage(cert)
      try generateQRSHATxt(cert)
      try generateCOSESHABin(cert)
      try generateCOSESHATxt(cert)
    } catch {
      completionHandler(.failure(error))
    }
    completionHandler(.success(data))
  }
  
  private func generateVersion() throws {
    do {
      try writeTextToFile(filename: "VERSION.txt",text: "1.00\n")
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
      try writeTextToFile(filename: "README.txt",text: readmeText)
    } catch {
      throw error
    }
  }
  
  private func generatePayloadSHABin(_ certificate: HCert) throws {
    if let cborData = CBOR.payloadBytes(from : certificate.cborData) {
      let data = SHA256.digest(input: Data(cborData) as NSData)
      do {
        try writeDataToFile(data: data, filename: "payload-sha.bin")
      } catch {
        throw error
      }
    }
  }
  
  private func generatePayloadSHATxt(_ certificate: HCert) throws {
    if let cborData = CBOR.payloadBytes(from: certificate.cborData) {
      let hexCborPayload = Data(cborData).hexString
      let shaData = SHA256.digest(input: hexCborPayload.data(using: .utf8)! as NSData)
      
      let text = shaData.hexString + "\n"
      do {
        try writeTextToFile(filename: "payload-sha.txt", text: text)
      } catch {
        throw error
      }
    }
  }
  
  private func generateQRBase64(_ certificate: HCert) throws {
    if let cose = COSE.signedPayloadBytes(from: certificate.cborData) {
      do {
        try writeDataToFile(data: cose.base64EncodedData(options: .endLineWithLineFeed), filename: "QR.base64")
      } catch {
        throw error
      }
    }
  }
  
  private func generatePayloadJson(_ certificate: HCert) throws {
    do {
      try writeTextToFile(filename: "payload.json", text: certificate.body.rawString() ?? "")
    } catch {
      throw error
    }
  }
  
  private func generateQRSHABin(_ certificate: HCert) throws {
    if let QRData = certificate.fullPayloadString.data(using: .ascii) {
      let data = SHA256.digest(input: QRData as NSData)
      do {
        try writeDataToFile(data: data, filename: "QR-sha.bin")
      } catch {
        throw error
      }
    }
  }
  
  private func generateQRSHATxt(_ certificate: HCert) throws {
    if let QRData = certificate.fullPayloadString.data(using: .ascii) {
      let shaData = SHA256.digest(input: QRData as NSData)
      
      let text = shaData.hexString + "\n"
      do {
        try writeTextToFile(filename: "QR-sha.txt", text: text)
      } catch {
        throw error
      }
    }
  }
  
  private func generateQRImage(_ certificate: HCert) throws {
    if let image = certificate.qrCode {
      if let data = image.pngData() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
          let fileURL = dir.appendingPathComponent("QR.png")
          do {
            try data.write(to: fileURL)
          } catch {
            throw error
          }
        }
      }
    }
  }
  
  private func generateQRTxt(_ certificate: HCert) throws {
    do {
      try writeTextToFile(filename: "QR.txt", text: certificate.fullPayloadString)
    } catch {
      throw error
    }
  }
  
  private func generateCOSESHABin(_ certificate: HCert) throws {
    if let cose = COSE.signedPayloadBytes(from: certificate.cborData) {
      let shaData = SHA256.digest(input: cose as NSData)
      do {
        try writeDataToFile(data: shaData, filename: "cose-sha.bin")
      } catch {
        throw error
      }
    }
  }
  
  private func generateCOSESHATxt(_ certificate: HCert) throws {
    if let cose = COSE.signedPayloadBytes(from: certificate.cborData) {
      
      let shaData = SHA256.digest(input: cose as NSData)
      do {
        try writeTextToFile(filename: "cose-sha.txt", text: shaData.hexString + "\n")
      } catch {
        throw error
      }
    }
  }
  
}

extension DebugModeManager {
  fileprivate func writeTextToFile(filename: String,text: String) throws {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let fileURL = dir.appendingPathComponent(filename)
      
      do {
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
      }
      catch {
        throw error
      }
    }
  }
  
  fileprivate func writeDataToFile(data: Data,filename: String) throws {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let fileURL = dir.appendingPathComponent(filename)
      
      do {
        try data.write(to: fileURL, options: .noFileProtection)
      }
      catch {
        throw error
      }
    }
  }
}
