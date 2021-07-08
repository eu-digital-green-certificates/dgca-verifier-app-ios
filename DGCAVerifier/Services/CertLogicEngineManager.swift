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
//  CertLogicEngineManager.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 23.06.2021.
//  
import Foundation
import CertLogic
import SwiftDGC

class CertLogicEngineManager {
  static var sharedInstance: CertLogicEngineManager = {
    let instance = CertLogicEngineManager()
    return instance
  }()

  var certLogicEngine: CertLogicEngine = CertLogicEngine(schema: SwiftDGC.euDgcSchemaV1, rules: [])
  func setRules(ruleList: [CertLogic.Rule]) {
    certLogicEngine.updateRules(rules: ruleList)
  }
  func validate(filter: FilterParameter, external: ExternalParameter, payload: String) -> [ValidationResult] {
    return certLogicEngine.validate(filter: filter, external: external, payload: payload)
  }
  func getRuleDetailsError(rule: Rule, filter: FilterParameter) -> Dictionary<String, String> {
    return certLogicEngine.getDetailsOfError(rule: rule, filter: filter)
  }
}
