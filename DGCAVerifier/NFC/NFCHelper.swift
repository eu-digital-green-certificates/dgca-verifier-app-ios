//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-wallet-app-ios
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
//  NFCHelper.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import Foundation
import CoreNFC
import SwiftDGC

class NFCHelper: NSObject, NFCNDEFReaderSessionDelegate {
  var onNFCResult: ((Bool, String) -> ())?
  func restartSession() {
    let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    session.begin()
  }
  
  // MARK: NFCNDEFReaderSessionDelegate
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    guard let onNFCResult = onNFCResult else { return }
    onNFCResult(false, error.localizedDescription)
  }
  
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    guard let onNFCResult = onNFCResult else { return }
    
    DGCLogger.logInfo("Detected NDEF")
    var payload = ""
    for message in messages {
      for record in message.records {
        DGCLogger.logInfo("NFC_READ: RECORD IDENTIFIER\(record.identifier)")
        DGCLogger.logInfo("NFC_READ: RECORD payload\(record.payload)")
        DGCLogger.logInfo("NFC_READ: RECORD type\(record.type)")
        DGCLogger.logInfo("NFC_READ: RECORD typeNameFormat\(record.typeNameFormat)")
        
        payload += "\(record.identifier)\n"
        payload += "\(record.payload)\n"
        payload += "\(record.type)\n"
        payload += "\(record.typeNameFormat)\n"
        
        if let resultString = String(data: record.payload, encoding: .utf8) {
          onNFCResult(true, resultString)
        } else {
          onNFCResult(false, "don't found any info")
        }
      }
    }
  }
}
