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
//  SectionBuilder.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 18.10.2021.
//  
        

import Foundation
import SwiftyJSON
import SwiftDGC
import CertLogic

class SectionBuilder {
    var infoSection = [InfoSection]()

    private let certificateValidity: CertificateValidity
    private let certificate: HCert

    init(with cert: HCert, validity: CertificateValidity) {
      self.certificate = cert
      self.certificateValidity = validity
    }

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

    func makeSectionForRuleError(ruleSection: InfoSection, for appType: AppType) {
      let hSection = InfoSection(header: l10n("header.cert-type"), content: certificate.certTypeString )
      infoSection += [hSection]

      guard certificateValidity.isValid else {
        let vSection = InfoSection(header: l10n("header.validity-errors"),
            content: certificateValidity.validityFailures.joined(separator: " "))
        infoSection += [vSection]
        return
      }
        
      infoSection += [ruleSection]
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

  // MARK: private section
    private func makeSectionsForVerifier(includeInvalidSection: Bool = true) {
      if includeInvalidSection {
        let hSection = InfoSection( header: l10n("header.cert-type"), content: certificate.certTypeString )
        infoSection += [hSection]
        if !certificateValidity.isValid {
          let vSection = InfoSection(header: l10n("header.validity-errors"),
              content: certificateValidity.validityFailures.joined(separator: " "))
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
        if !certificateValidity.isValid {
          let hSection = InfoSection(header: l10n("header.validity-errors"),
            content: certificateValidity.validityFailures.joined(separator: " "))
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
        if !certificateValidity.isValid {
          let hSection = InfoSection(header: l10n("header.validity-errors"),
              content: certificateValidity.validityFailures.joined(separator: " "))
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
        if !certificateValidity.isValid {
          let vSection = InfoSection(header: l10n("header.validity-errors"),
              content: certificateValidity.validityFailures.joined(separator: " "))
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
