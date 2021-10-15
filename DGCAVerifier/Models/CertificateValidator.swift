//
//  CertificateValidator..swift
//  
//
//  Created by Igor Khomiak on 15.10.2021.
//

import Foundation
import SwiftyJSON
import SwiftDGC
import CertLogic

class CertificateValidator {
  var technicalVerification: HCertValidity = .invalid
  var issuerInvalidation: RuleValidationResult = .error
  var destinationAcceptence: RuleValidationResult = .error
  var travalerAcceptence: RuleValidationResult = .error
  var validityFailures = [String]()
  
  var infoSection = [InfoSection]()
  
  private let certificate: HCert
  private var validity: HCertValidity {
    return validityFailures.isEmpty ? .valid : .invalid
  }
  
  private var isValid: Bool {
    return validityFailures.isEmpty
  }

  @discardableResult
  func validate() -> HCertValidity {
    findValidityFailures()
    technicalVerification = performTechnicalValidation()
    
    let validResutl = validateCertLogicForIssuer()
    switch validResutl {
      case .valid:
        issuerInvalidation = .passed
      case .invalid:
        issuerInvalidation = .error
      case .ruleInvalid:
        issuerInvalidation = .open
    }
    let validResut2 = validateCertLogicForDestination()
    switch validResut2 {
      case .valid:
        destinationAcceptence = .passed
      case .invalid:
        destinationAcceptence = .error
      case .ruleInvalid:
        destinationAcceptence = .open
    }
    let validResut3 = validateCertLogicForTraveller()
    switch validResut3 {
      case .valid:
        travalerAcceptence = .passed
      case .invalid:
        travalerAcceptence = .error
      case .ruleInvalid:
        travalerAcceptence = .open
    }
    
    let result: HCertValidity
    if technicalVerification == .valid {
        result = validateCertLogicForAllRules()
    } else {
      result =  .invalid
    }
    makeSections(for: self.certificate.appType)
    return result
  }
  
  init(with cert: HCert) {
    self.certificate = cert
  }

  func findValidityFailures() {
    validityFailures = []
    if !certificate.cryptographicallyValid {
      validityFailures.append(l10n("hcert.err.crypto"))
    }
    if certificate.exp < HCert.clock {
      validityFailures.append(l10n("hcert.err.exp"))
    }
    if certificate.iat > HCert.clock {
      validityFailures.append(l10n("hcert.err.iat"))
    }
    if certificate.statement == nil {
      return validityFailures.append(l10n("hcert.err.empty"))
    }
    validityFailures.append(contentsOf: certificate.statement.validityFailures)
  }

  // MARK: validation
  private func performTechnicalValidation() -> HCertValidity {
      return validity
  }

  private func validateCertLogicForAllRules() -> HCertValidity {
      var validity: HCertValidity = .valid
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
            countryCode: countryCode,
            certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
             valueSets: valueSets,
             exp: certificate.exp,
             iat: certificate.iat,
             issuerCountryCode: certificate.issCode,
             kid: certificate.kidStr)
        let result = CertLogicEngineManager.sharedInstance.validate(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        let failsAndOpen = result.filter { $0.result != .passed }
        
        if failsAndOpen.count > 0 {
          validity = .ruleInvalid
          var section = InfoSection(header: "Possible limitation", content: "Country rules validation failed")
          var listOfRulesSection: [InfoSection] = []
          result.sorted(by: { $0.result.rawValue < $1.result.rawValue }).forEach { validationResult in
            if let error = validationResult.validationErrors?.first {
              switch validationResult.result {
              case .fail:
                listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                    content: error.localizedDescription,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: SwiftDGC.RuleValidationResult.error))
              case .open:
                listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                    content: l10n(error.localizedDescription),
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: SwiftDGC.RuleValidationResult.open))
              case .passed:
                listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                    content: error.localizedDescription,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: SwiftDGC.RuleValidationResult.passed))
              }
              
            } else {
              let preferredLanguage = Locale.preferredLanguages[0] as String
              let arr = preferredLanguage.components(separatedBy: "-")
              let deviceLanguage = (arr.first ?? "EN")
              var errorString = ""
              if let error = validationResult.rule?.getLocalizedErrorString(locale: deviceLanguage) {
                errorString = error
              }
              var detailsError = ""
              if let rule = validationResult.rule {
                let dict = CertLogicEngineManager.sharedInstance.getRuleDetailsError(rule: rule, filter: filterParameter)
                dict.keys.forEach({ detailsError += $0 + ": " + (dict[$0] ?? "") + " " })
              }
              switch validationResult.result {
              case .fail:
                listOfRulesSection.append(InfoSection(header: errorString,
                    content: detailsError,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: SwiftDGC.RuleValidationResult.error))
              case .open:
                listOfRulesSection.append(InfoSection(header: errorString,
                    content: detailsError,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: SwiftDGC.RuleValidationResult.open))
              case .passed:
                listOfRulesSection.append(InfoSection(header: errorString,
                    content: detailsError,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: SwiftDGC.RuleValidationResult.passed))
              }
            }
          }
          section.sectionItems = listOfRulesSection
          makeSectionForRuleError(infoSections: section, for: .verifier)
        }
      }
      return validity
    }
    
    func validateCertLogicForIssuer() -> HCertValidity {
      let validity: HCertValidity = .valid
      
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
            countryCode: countryCode,
            certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
           valueSets: valueSets,
           exp: certificate.exp,
           iat: certificate.iat,
           issuerCountryCode: certificate.issCode,
           kid: certificate.kidStr)
        let result = CertLogicEngineManager.sharedInstance.validateIssuer(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        let fails = result.filter { $0.result == .fail }
        if !fails.isEmpty {
          return .invalid
        }
        let open = result.filter { $0.result == .open }
        if !open.isEmpty {
          return .ruleInvalid
        }
      }
      return validity
    }

    func validateCertLogicForDestination() -> HCertValidity {
      let validity: HCertValidity = .valid
      
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
          countryCode: countryCode,
          certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
          valueSets: valueSets,
          exp: certificate.exp,
          iat: certificate.iat,
          issuerCountryCode: certificate.issCode,
          kid: certificate.kidStr)
        let result = CertLogicEngineManager.sharedInstance.validateDestination(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        let fails = result.filter { $0.result == .fail }
        if !fails.isEmpty {
          return .invalid
        }
        let open = result.filter { $0.result == .open }
        if !open.isEmpty {
          return .ruleInvalid
        }
      }
      return validity
    }
    
    func validateCertLogicForTraveller() -> HCertValidity {
      let validity: HCertValidity = .valid
      
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
            countryCode: countryCode,
            certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
           valueSets: valueSets,
           exp: certificate.exp,
           iat: certificate.iat,
           issuerCountryCode: certificate.issCode,
           kid: certificate.kidStr)
        let result = CertLogicEngineManager.sharedInstance.validateTraveller(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        
        let fails = result.filter { $0.result == .fail }
        if !fails.isEmpty {
          return .invalid
        }
        let open = result.filter { $0.result == .open }
        if !open.isEmpty {
          return .ruleInvalid
        }
      }
      return validity
    }
    
    private func certificationType(for type: SwiftDGC.HCertType) -> CertificateType {
      switch type {
      case .recovery:
        return .recovery
      case .test:
        return .test
      case .vaccine:
        return .vaccination
      case .unknown:
        return .general
      }
    }
}

// MARK: infp table Maker
extension CertificateValidator {

  func makeSections(for appType: AppType) {
    infoSection.removeAll()
    switch appType {
    case .verifier:
        makeSectionsForVerifier()
    case .wallet:
      switch certificate.certificateType {
        case .vaccine:
          makeSectionsForVaccine()
      case .test:
        makeSectionsForTest()
      case .recovery:
        makeSectionsForRecovery()
      default:
        makeSectionsForVerifier()
      }
    }
  }

  private func makeSectionForRuleError(infoSections: InfoSection, for appType: AppType) {
    let hSection = InfoSection(header: l10n("header.cert-type"), content: certificate.certTypeString )
    infoSection += [hSection]

    guard isValid else {
      let vSection = InfoSection(header: l10n("header.validity-errors"), content: validityFailures.joined(separator: " "))
      infoSection += [vSection]
      return
    }
      
    infoSection += [infoSections]
    switch appType {
    case .verifier:
        makeSectionsForVerifier(includeInvalidSection: false)
    case .wallet:
      switch certificate.certificateType {
      case .vaccine:
        makeSectionsForVaccine(includeInvalidSection: false)
      case .test:
        makeSectionsForTest()
      case .recovery:
        makeSectionsForRecovery(includeInvalidSection: false)
      default:
        makeSectionsForVerifier(includeInvalidSection: false)
      }
    }
  }

  private func makeSectionsForVerifier(includeInvalidSection: Bool = true) {
    if includeInvalidSection {
      let hSection = InfoSection( header: l10n("header.cert-type"), content: certificate.certTypeString )
      infoSection += [hSection]
      if !isValid {
        let vSection = InfoSection(header: l10n("header.validity-errors"), content: validityFailures.joined(separator: " "))
        infoSection += [vSection]
        return
      }
    }
    let hSection = InfoSection( header: l10n("header.std-fn"),
        content: certificate.lastNameStandardized.replacingOccurrences( of: "<", with: String.zeroWidthSpace + "<" + String.zeroWidthSpace), style: .fixedWidthFont)
    infoSection += [hSection]
    
    infoSection += [InfoSection( header: l10n("header.std-gn"),
        content: certificate.firstNameStandardized.replacingOccurrences( of: "<",
        with: String.zeroWidthSpace + "<" + String.zeroWidthSpace), style: .fixedWidthFont)]
    let sSection = InfoSection( header: l10n("header.dob"), content: certificate.dateOfBirth)
    infoSection += [sSection]
    infoSection += certificate.statement == nil ? [] : certificate.statement.info
    let uSection = InfoSection(header: l10n("header.uvci"),content: certificate.uvci,style: .fixedWidthFont,isPrivate: true)
    infoSection += [uSection]
    if !certificate.issCode.isEmpty {
      let cSection = InfoSection(header: l10n("issuer.country"),content: l10n("country.\(certificate.issCode.uppercased())"))
      infoSection += [cSection]
    }
  }
  
  private func makeSectionsForVaccine(includeInvalidSection: Bool = true) {
    if includeInvalidSection {
      let cSection = InfoSection( header: l10n("header.cert-type"),content: certificate.certTypeString)
      infoSection += [cSection]
      if !isValid {
        let hSection = InfoSection(header: l10n("header.validity-errors"), content: validityFailures.joined(separator: " "))
        infoSection += [hSection]
      }
    }
    let fullName = certificate.fullName
    if !fullName.isEmpty {
      let sSection = InfoSection( header: l10n("section.name"), content: fullName, style: .fixedWidthFont )
      infoSection += [sSection]
    }
    infoSection += certificate.statement == nil ? [] : certificate.statement.walletInfo
    if certificate.issCode.count > 0 {
      let cSection = InfoSection( header: l10n("issuer.country"), content: l10n("country.\(certificate.issCode.uppercased())"))
      infoSection += [cSection]
    }
  }
  
  private func makeSectionsForTest(includeInvalidSection: Bool = true) {
    if includeInvalidSection {
      let cSection = InfoSection(header: l10n("header.cert-type"), content: certificate.certTypeString)
      infoSection += [cSection]
      if !isValid {
        let hSection = InfoSection(header: l10n("header.validity-errors"), content: validityFailures.joined(separator: " "))
        infoSection += [hSection]
      }
    }
    let fullName = certificate.fullName
    if !fullName.isEmpty {
      let section = InfoSection(header: l10n("section.name"), content: fullName, style: .fixedWidthFont)
      infoSection += [section]
    }
    infoSection += certificate.statement == nil ? [] : certificate.statement.walletInfo
    let section = InfoSection( header: l10n("issuer.country"), content: l10n("country.\(certificate.issCode.uppercased())"))
    if !certificate.issCode.isEmpty {
      infoSection += [section]
    }
  }

  private func makeSectionsForRecovery(includeInvalidSection: Bool = true) {
    if includeInvalidSection {
      let hSection = InfoSection(header: l10n("header.cert-type"), content: certificate.certTypeString)
      infoSection += [hSection]
      if !isValid {
        let vSection = InfoSection(header: l10n("header.validity-errors"), content: validityFailures.joined(separator: " "))
        infoSection += [vSection]
      }
    }
    let fullName = certificate.fullName
    if !fullName.isEmpty {
      let nSection = InfoSection( header: l10n("section.name"), content: fullName, style: .fixedWidthFont)
      infoSection += [nSection]
    }
    infoSection += certificate.statement == nil ? [] : certificate.statement.walletInfo
    if !certificate.issCode.isEmpty {
      let iSection = InfoSection(header: l10n("issuer.country"), content: l10n("country.\(certificate.issCode.uppercased())"))
      infoSection += [iSection]
    }
  }
}
