<h1 align="center">
    EU Digital COVID Certificate Verifier App - iOS
</h1>

<p align="center">
    <a href="/../../commits/" title="Last Commit"><img src="https://img.shields.io/github/last-commit/ministero-salute/dgca-verifier-app-ios?style=flat"></a>
    <a href="/../../issues" title="Open Issues"><img src="https://img.shields.io/github/issues/ministero-salute/dgca-verifier-app-ios?style=flat"></a>
    <a href="./LICENSE" title="License"><img src="https://img.shields.io/badge/License-Apache%202.0-green.svg?style=flat"></a>
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#development">Development</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#dependencies">Dependencies</a> •
  <a href="#support-and-feedback">Support</a> •
  <a href="#how-to-contribute">Contribute</a> •
  <a href="#contributors">Contributors</a> •
  <a href="#licensing">Licensing</a>
</p>

## About

This repository contains the source code of *VerificaC19*, the Italian customization of the EU Digital COVID Certificate Verifier App for the iOS Operating System. The repository is forked from the [official EU Digital COVID Certificate Verifier App - iOS](https://github.com/eu-digital-green-certificates/dgca-verifier-app-ios).

The DGC Verifier Apps are responsible for scanning and verifying DCCs using public keys from national backend servers. Offline verification is supported, if the latest public keys are present in the app's key store. Consequently, once up-to-date keys have been downloaded, the verification works without active internet connection.
The Italian version adds some medical rules to the validation of the DCCs, defined by rules downloaded from national backend servers.

## Translators 💬

You can help the localization of this project by making contributions to the [/Resources/Localizable.strings](Resources/Localizable.strings).

## Development

### Prerequisites

- You need a Mac to run Xcode.
- Xcode 12.5+ is used for our builds. The OS requirement is macOS 11.0+.
- To install development apps on physical iPhones, you need an Apple Developer account.
- Service Endpoints:
  - This App talks to the endpoint: `https://get.dgc.gov.it/v1/dgc/` to retrieve kids, public keys, settings and medical rules for prod configuration,
  - To get QR Codes for testing, you might want to check out `https://dgc.a-sit.at/ehn/testsuite`.

### Build

Whether you cloned or downloaded the 'zipped' sources you will either find the sources in the chosen checkout-directory or get a zip file with the source code, which you can expand to a folder of your choice.

#### Xcode based build


Important Info: SPM and the SwiftDGC [core module](https://github.com/eu-digital-green-certificates/dgca-app-core-ios)
- Depending on the development status, this module might be either linked locally or via github URL.
- If it's linked locally, you should clone both repos into the same folder:
- `<project folder>`
    - `dgca-app-core-ios`
    - `dgca-verifier-app-ios`
- Otherwise it will be pulled by Xcode like all other SPM modules.
    - Make sure the core module is up to date by clicking File > Swift Packages > Update Packages.

Build steps
- Set the development team to any Apple Developer Account
- Give the project a unique bundle identifier
- Install swift package manager requirements through Xcode 12.5+
- Build and run the project through Xcode 12.5+

## Documentation

- [High level documentation](https://github.com/ministero-salute/it-dgc-documentation)

## Dependencies

The following dependencies are used in the project  by the verifier app and the core app and are imported as Swift Packages:
- **[SwiftDGC](https://github.com/eu-digital-green-certificates/dgca-app-core-ios).** Eurpean core library that contains business logic to decode data from QR code payload and performs technical validations (i.e. correct signature verification, signature expiration verification, correct payload format etc).
- **[Alamofire](https://github.com/Alamofire/Alamofire).** Library used for networking.
- **[JSONSchema](https://github.com/eu-digital-green-certificates/JSONSchema.swift).** Library used by core module to validate DCC payload JSON schema.
- **[SwiftCBOR](https://github.com/eu-digital-green-certificates/SwiftCBOR).** Library used by core module for CBOR specification implementation.
- **[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).** Library used by core module to translate data from JSON format.
All listed dependencies are already included in the [official EU Digital COVID Certificate Verifier App for iOS] (https://github.com/eu-digital-green-certificates/dgca-verifier-app-ios). No new dependencies have been included in the Italian customization of the app.

## Support and feedback

The following channels are available for discussions, feedback, and support requests:

| Type               | Channel                                                                                                                                                                          |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Issues**         | <a href="/../../issues" title="Open Issues"><img src="https://img.shields.io/github/issues/ministero-salute/dgca-verifier-app-ios?style=flat"></a>                  |

## How to contribute

Contribution and feedback is encouraged and always welcome. For more information about how to contribute, the project structure, as well as additional contribution information, see our [Contribution Guidelines](./CONTRIBUTING.md). By participating in this project, you agree to abide by its [Code of Conduct](./CODE_OF_CONDUCT.md) at all times.

## Contributors

Our commitment to open source means that we are enabling -in fact encouraging- all interested parties to contribute and become part of its developer community.

## Licensing

Copyright (C) 2021 T-Systems International GmbH and all other contributors

Licensed under the **Apache License, Version 2.0** (the "License"); you may not use this file except in compliance with the License.

You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the [LICENSE](./LICENSE) for the specific language governing permissions and limitations under the License.
