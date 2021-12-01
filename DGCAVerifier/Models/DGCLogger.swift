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
//  DGCLogger.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 21.10.2021.
//  
        

import UIKit

public enum DGCLogger {}

// MARK: - Public
extension DGCLogger {
    public static func logInfo(_ message: String, file: NSString = #file, function: String = #function, line: Int = #line) {
        log(message, tag: .info, file: file, function: function, line: line)
    }
    
    public static func logError(_ message: String, file: NSString = #file, function: String = #function, line: Int = #line) {
        log(message, tag: .error, file: file, function: function, line: line)
    }
    
    public static func logError(_ error: Error, file: NSString = #file, function: String = #function, line: Int = #line) {
        log(error, tag: .error, file: file, function: function, line: line)
    }
}

// MARK: - Private
private extension DGCLogger {
    
    enum Tag: String {
        case error
        case info
    }
    
    static func log(_ value: Any, tag: Tag, file: NSString, function: String, line: Int) {
        #if DEBUG
        let valueString = "\(value)".padEnd(length: 50)
        print(" [ \(tag.rawValue.uppercased()) ] \(valueString) \t: \(function) \(file.lastPathComponent):\(line)")
        #endif
    }
}
