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
//  GatewayConnection.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/24/21.
//  

import UIKit
import Alamofire
import SwiftDGC
import SwiftyJSON
import CertLogic

class GatewayConnection: ContextConnection {
  public static func certUpdate(resume resumeToken: String? = nil, completion: ((String?, String?) -> Void)?) {
    var headers = [String: String]()
    if let token = resumeToken {
      headers["x-resume-token"] = token
    }
    request( ["endpoints", "update"],
      method: .get,
      encoding: URLEncoding(),
      headers: .init(headers)).response {
      if let status = $0.response?.statusCode, status == 204 {
        completion?(nil, nil)
        return
      }
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let headers = $0.response?.headers,
        let responseKid = headers["x-kid"],
        let newResumeToken = headers["x-resume-token"]
      else {
        completion?(nil, nil)
        return
      }
      let kid = KID.from(responseStr)
      let kidStr = KID.string(from: kid)
      if kidStr != responseKid {
        completion?(nil, newResumeToken)
        return
      }
      completion?(responseStr, newResumeToken)
    }
  }

  public static func certStatus(resume resumeToken: String? = nil, completion: (([String]) -> Void)?) {
    request(["endpoints", "status"]).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let json = JSON(parseJSON: responseStr).array
      else {
        completion?([])
        return
      }
      let kids = json.compactMap { $0.string }
      completion?(kids)
    }
  }

  static var timer: Timer?

  public static func initialize() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
      trigger()
    }
    timer?.tolerance = 5.0
    trigger()
  }

  static func trigger() {
    guard LocalStorage.dataKeeper.localData.lastFetch.timeIntervalSinceNow < -24 * 60 * 60 else { return }
    update()
  }

  static func update(completion: (() -> Void)? = nil) {
    certUpdate(resume: LocalStorage.dataKeeper.localData.resumeToken) { encodedCert, token in
      guard let encodedCert = encodedCert else {
        status(completion: completion)
        return
      }
      LocalStorage.dataKeeper.add(encodedPublicKey: encodedCert)
      LocalStorage.dataKeeper.localData.resumeToken = token
      update(completion: completion)
    }
  }

  static func status(completion: (() -> Void)? = nil) {
    certStatus { validKids in
      let invalid = LocalStorage.dataKeeper.localData.encodedPublicKeys.keys.filter { !validKids.contains($0) }
      for key in invalid {
        LocalStorage.dataKeeper.localData.encodedPublicKeys.removeValue(forKey: key)
      }
      LocalStorage.dataKeeper.localData.lastFetch = Date()
      LocalStorage.dataKeeper.save()
      completion?()
    }
  }

  public static func fetchContext(completion: (() -> Void)? = nil) {
    request( ["context"] ).response {
      guard let data = $0.data, let string = String(data: data, encoding: .utf8) else {
        completion?()
        return
      }
      let json = JSON(parseJSONC: string)
      LocalStorage.dataKeeper.localData.config.merge(other: json)
      LocalStorage.dataKeeper.save()
      if LocalStorage.dataKeeper.versionedConfig["outdated"].bool == true {
        (UIApplication.shared.windows[0].rootViewController as? UINavigationController)?
            .popToRootViewController(animated: false)
      }
      completion?()
    }
  }
  static var config: JSON {
    return LocalStorage.dataKeeper.versionedConfig
  }
}

// MARK: Country, Rules, Valuesets extension
extension GatewayConnection {
  // Country list
  public static func getListOfCountry(completion: (([CountryModel]) -> Void)?) {
    request(["endpoints", "countryList"], method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let json = JSON(parseJSON: responseStr).array
      else {
        completion?([])
        return
      }
        
      let codes = json.compactMap { $0.string }
      var countryList: [CountryModel] = []
      codes.forEach { countryList.append(CountryModel(code: $0)) }
      completion?(countryList)
    }
  }
  
  static func loadCountryList(completion: (([CountryModel]) -> Void)? = nil) {
     if !LocalStorage.countryCodes.isEmpty {
      completion?(LocalStorage.countryCodes.sorted(by: { $0.name < $1.name }))
    } else {
      getListOfCountry { countryList in
        // Remove old countryCodes
        let newCountryCodes = LocalStorage.countryCodes.filter { countryCode in
            return countryList.contains(where: { $0.code == countryCode.code })
        }
        LocalStorage.countryCodes = newCountryCodes
        countryList.forEach { LocalStorage.countryKeeper.add(country: $0) }
        LocalStorage.saveCountries()

        completion?(LocalStorage.countryCodes.sorted(by: { $0.name < $1.name }))
      }
    }
  }
  
  // Rules
  public static func getListOfRules(completion: (([CertLogic.Rule]) -> Void)?) {
    request(["endpoints", "rules"], method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else {
        completion?([])
        return
      }
      
      let ruleHashes: [RuleHash] = CertLogicEngine.getItems(from: responseStr)
      // Remove old hashes
      LocalStorage.rulesKeeper.rulesData.rules = LocalStorage.rulesKeeper.rulesData.rules.filter { rule in
        return !ruleHashes.contains(where: { $0.hash == rule.hash })
      }
      // Downloading new hashes
      var rulesItems = [CertLogic.Rule]()
      let downloadingGroup = DispatchGroup()
      ruleHashes.forEach { ruleHash in
        downloadingGroup.enter()
        if !LocalStorage.rulesKeeper.isRuleExistWithHash(hash: ruleHash.hash) {
          getRules(ruleHash: ruleHash) { rule in
            if let rule = rule {
              rulesItems.append(rule)
            }
            downloadingGroup.leave()
          }
        } else {
          downloadingGroup.leave()
        }
      }
      downloadingGroup.notify(queue: .main) {
        completion?(rulesItems)
        DGCLogger.logInfo("Finished all requests.")
      }
    }
  }
  
  public static func getRules(ruleHash: CertLogic.RuleHash, completion: ((CertLogic.Rule?) -> Void)?) {
    request(["endpoints", "rules"], externalLink: "/\(ruleHash.country)/\(ruleHash.hash)", method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else {
        completion?(nil)
        return
      }
      if let rule: Rule = CertLogicEngine.getItem(from: responseStr) {
        let downloadedRuleHash = SHA256.digest(input: response as NSData)
        if downloadedRuleHash.hexString == ruleHash.hash {
          rule.setHash(hash: ruleHash.hash)
          completion?(rule)
        } else {
          completion?(nil)
        }
        return
      }
      completion?(nil)
    }
  }
  
  static func rulesList(completion: (([CertLogic.Rule]) -> Void)? = nil) {
    LocalStorage.rulesKeeper.initialize {
      completion?(LocalStorage.rulesKeeper.rulesData.rules)
    }
  }
  
  static func loadRulesFromServer(completion: (([CertLogic.Rule]) -> Void)? = nil) {
    getListOfRules { rulesList in
        rulesList.forEach { LocalStorage.rulesKeeper.add(rule: $0) }
      LocalStorage.saveRules()
      completion?(LocalStorage.rulesKeeper.rulesData.rules)
    }
  }
  
  // ValueSets
  public static func getListOfValueSets(completion: (([CertLogic.ValueSet]) -> Void)?) {
    request(["endpoints", "valuesets"], method: .get).response {
      guard
        case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else {
        completion?([])
        return
      }
      let valueSetsHashes: [ValueSetHash] = CertLogicEngine.getItems(from: responseStr)
      // Remove old hashes
      LocalStorage.valueSetsKeeper.valueSetsData.valueSets = LocalStorage.valueSetsKeeper.valueSetsData.valueSets.filter { valueSet in
        return !valueSetsHashes.contains(where: { $0.hash == valueSet.hash })
      }
      // Downloading new hashes
      var valueSetsItems = [CertLogic.ValueSet]()
      let downloadingGroup = DispatchGroup()
      valueSetsHashes.forEach { valueSetHash in
        downloadingGroup.enter()
        if !LocalStorage.valueSetsKeeper.isValueSetExistWithHash(hash: valueSetHash.hash) {
          getValueSets(valueSetHash: valueSetHash) { valueSet in
            if let valueSet = valueSet {
              valueSetsItems.append(valueSet)
            }
            downloadingGroup.leave()
          }
        } else {
          downloadingGroup.leave()
        }
      }
      downloadingGroup.notify(queue: .main) {
        completion?(valueSetsItems)
        DGCLogger.logInfo("Finished all requests.")
      }
    }
  }
    
  public static func getValueSets(valueSetHash: CertLogic.ValueSetHash, completion: ((CertLogic.ValueSet?) -> Void)?) {
    request(["endpoints", "valuesets"], externalLink: "/\(valueSetHash.hash)", method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else {
        completion?(nil)
        return
      }
      if let valueSet: ValueSet = CertLogicEngine.getItem(from: responseStr) {
        let downloadedValueSetHash = SHA256.digest(input: response as NSData)
        if downloadedValueSetHash.hexString == valueSetHash.hash {
          valueSet.setHash(hash: valueSetHash.hash)
          completion?(valueSet)
        } else {
          completion?(nil)
        }
        return
      }
      completion?(nil)
    }
  }
    
  static func valueSetsList(completion: (([CertLogic.ValueSet]) -> Void)? = nil) {
    LocalStorage.valueSetsKeeper.initialize {
        completion?(LocalStorage.valueSetsKeeper.valueSetsData.valueSets)
    }
  }

  static func loadValueSetsFromServer(completion: (([CertLogic.ValueSet]) -> Void)? = nil){
    getListOfValueSets { valueSetsList in
      valueSetsList.forEach { LocalStorage.valueSetsKeeper.add(valueSet: $0) }
      LocalStorage.saveSets()
      completion?(LocalStorage.valueSetsKeeper.valueSetsData.valueSets)
    }
  }
}
