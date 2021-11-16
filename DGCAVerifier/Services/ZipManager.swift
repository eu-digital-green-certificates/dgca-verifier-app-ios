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
//  ZipManager.swift
//  DGCAVerifier
//  
//  Created by Illia Vlasov on 03.09.2021.
//  

import UIKit
import SwiftDGC
import SwiftyJSON
import Zip

class ZipManager {
  func prepareZipData(_ cert: HCert, completionHandler: @escaping (Result<URL, Error>) -> Void) {
    do {
      try createCertificateFolder()
      
      switch DebugManager.sharedInstance.debugLevel {
      case .level3:
        try generateQRImage(cert)
        try generateCOSESHABin(cert)
        try generateCOSESHATxt(cert)
        try generateCOSEBase64(cert)
        try generatePayloadBase64(cert)
        fallthrough
      case .level2:
        try generateQRSHABin(cert)
        try generateQRSHATxt(cert)
        fallthrough
      case .level1:
        try generateVersion()
        try generateReadme()
        try generatePayloadSHABin(cert)
        try generatePayloadSHATxt(cert)
        try generateQRBase64(cert)
        try generatePayloadJson(cert)
      }
      
      let certificateDirectoryURL = getCertificateDirectoryURL()
      archiveFileDirectory(url: certificateDirectoryURL, to: "archive") { (path, error) in
        guard error == nil, let archivePath = path else {
          completionHandler(.failure(error!))
          return
        }
        completionHandler(.success(archivePath))
      }
      
    } catch {
      completionHandler(.failure(error))
      return
    }
  }

//  private func archive() throws -> URL {
//    do {
//      let filesURLs = getCertificateFolderContentsURLs()
//      let zipFilePath = try Zip.quickZipFiles(filesURLs, fileName: "archive")
//      return zipFilePath
//    }
//    catch {
//      throw error
//    }
//  }
  
  
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
      do {
        try writeDataToFile(data: certificate.cborData.base64EncodedData(options: .endLineWithLineFeed), filename: "QR.base64")
      } catch {
        throw error
      }
  }
  
  private func generatePayloadJson(_ certificate: HCert) throws {
    do {
      let jsonString = anonymizedJsonPayload(certificate.body)
      try writeTextToFile(filename: "payload.json", text: jsonString)
    } catch {
      throw error
    }
  }
  
  private func anonymizedJsonPayload(_ json : JSON) -> String {
    var anonimzedJSON = json
    if DebugManager.sharedInstance.debugLevel == .level1 {
      anonimzedJSON["nam"]["gnt"].string = anonimzedJSON["nam"]["gnt"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      anonimzedJSON["nam"]["gn"].string = anonimzedJSON["nam"]["gn"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      anonimzedJSON["nam"]["fn"].string = anonimzedJSON["nam"]["fn"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      anonimzedJSON["nam"]["fnt"].string = anonimzedJSON["nam"]["fnt"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      
      if let dob = anonimzedJSON["dob"].string {
        var strchars = Array(dob)
        strchars[5] = "9"
        strchars[6] = "9"
        strchars[8] = "9"
        strchars[9] = "9"
        let dobStringAnonimized = String(strchars)
        anonimzedJSON["dob"].string = dobStringAnonimized
      }
      
      if let dt = anonimzedJSON["v"]["dt"].string {
        var strchars = Array(dt)
        strchars[5] = "9"
        strchars[6] = "9"
        strchars[8] = "9"
        strchars[9] = "9"
        let dtStringAnonimized = String(strchars)
        anonimzedJSON["v"]["dt"].string = dtStringAnonimized
      }
      
      anonimzedJSON["ci"].string?.removeLast(26)
      anonimzedJSON["ci"].string?.append("XXXXXXXXXXXXXXXXXXXXXXXXXX")
      
    } else if DebugManager.sharedInstance.debugLevel == .level2 {
      anonimzedJSON["nam"]["gnt"].string = anonimzedJSON["nam"]["gnt"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      anonimzedJSON["nam"]["gn"].string = anonimzedJSON["nam"]["gn"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      anonimzedJSON["nam"]["fn"].string = anonimzedJSON["nam"]["fn"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      anonimzedJSON["nam"]["fnt"].string = anonimzedJSON["nam"]["fnt"].string?.replacingOccurrences(of: "[a-zA-Z]", with: "X", options: .regularExpression, range: nil)
      
      if let dob = anonimzedJSON["dob"].string {
        var strchars = Array(dob)
        strchars[5] = "9"
        strchars[6] = "9"
        strchars[8] = "9"
        strchars[9] = "9"
        let dobStringAnonimized = String(strchars)
        anonimzedJSON["dob"].string = dobStringAnonimized
      }
    }
    
    return anonimzedJSON.rawString() ?? ""
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
    if let image = certificate.qrCode, let data = image.pngData() {
      do {
        try data.write(to: getCertificateDirectoryURL().appendingPathComponent("QR.png"))
      } catch {
        throw error
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
    let shaData = SHA256.digest(input: certificate.cborData as NSData)
    do {
      try writeDataToFile(data: shaData, filename: "cose-sha.bin")
    } catch {
      throw error
    }
  }
  
  private func generateCOSESHATxt(_ certificate: HCert) throws {
    let shaData = SHA256.digest(input: certificate.cborData as NSData)
    do {
      try writeTextToFile(filename: "cose-sha.txt", text: shaData.hexString + "\n")
    } catch {
      throw error
    }
  }
  
  private func generateCOSEBase64(_ certificate: HCert) throws {
      do {
        try writeDataToFile(data: certificate.cborData.base64EncodedData(options: .endLineWithLineFeed), filename: "cose.base64")
      } catch {
        throw error
      }
  }
  
  private func generatePayloadBase64(_ certificate: HCert) throws {
    do {
      try writeDataToFile(data: certificate.fullPayloadString.data(using:.utf8)!.base64EncodedData(options: .endLineWithLineFeed), filename: "payload.base64")
    } catch {
      throw error
    }
  }
}

extension ZipManager {
  fileprivate func getCertificateDirectoryURL() -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = dir.appendingPathComponent("Certificate", isDirectory: true)
    return fileURL
  }
  
  func getCertificateFolderContentsURLs() -> [URL] {
    guard let urls = try? FileManager().contentsOfDirectory(at: getCertificateDirectoryURL(), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return [] }
    return urls
  }
  
  fileprivate func createCertificateFolder() throws {
    var isDirectory:ObjCBool = true
    
    if !FileManager.default.fileExists(atPath: getCertificateDirectoryURL().path, isDirectory: &isDirectory) {
      do {
        try FileManager.default.createDirectory(at: getCertificateDirectoryURL(), withIntermediateDirectories: false, attributes: nil)
      } catch {
        throw error
      }
    }
  }
  
  fileprivate func deleteCertificateFolderAndZip() throws {
    do {
      try FileManager.default.removeItem(at: getCertificateDirectoryURL())
      try FileManager.default.removeItem(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("archive.zip", isDirectory: false))
    } catch {
      throw error
    }
  }
  
  fileprivate func writeTextToFile(filename: String,text: String) throws {
    let fileURL = getCertificateDirectoryURL().appendingPathComponent(filename)
    
    do {
      try text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    catch {
      throw error
    }
  }
  
  fileprivate func writeDataToFile(data: Data,filename: String) throws {
    let fileURL = getCertificateDirectoryURL().appendingPathComponent(filename)
    
    do {
      try data.write(to: fileURL, options: .noFileProtection)
    }
    catch {
      throw error
    }
  }
  
  
  private func archiveFileDirectory(url: URL, to archiveName: String, completion: @escaping (URL?, Error?) -> Void) {
      let fileManager = FileManager.default
      // this will hold the URL of the zip file
      
      let coordinator = NSFileCoordinator()

      var error: NSError?
      coordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &error) { (zipUrl) in
          // zipUrl points to the zip file created by the coordinator
        do {
          let tmpUrl = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask,
            appropriateFor: zipUrl, create: true).appendingPathComponent("\(archiveName).zip")

          try fileManager.moveItem(at: zipUrl, to: tmpUrl)

          completion(tmpUrl, nil)
        } catch {
          print(error.localizedDescription)
          completion(nil, error)
        }
      }
    }
}

