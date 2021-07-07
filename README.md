<h1 align="center">
    EU Digital COVID Certificate Verifier App - iOS
</h1>

<p align="center">
    <a href="/../../commits/" title="Last Commit"><img src="https://img.shields.io/github/last-commit/eu-digital-green-certificates/dgca-verifier-app-ios?style=flat"></a>
    <a href="/../../issues" title="Open Issues"><img src="https://img.shields.io/github/issues/eu-digital-green-certificates/dgca-verifier-app-ios?style=flat"></a>
    <a href="./LICENSE" title="License"><img src="https://img.shields.io/badge/License-Apache%202.0-green.svg?style=flat"></a>
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#development">Development</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#support-and-feedback">Support</a> •
  <a href="#how-to-contribute">Contribute</a> •
  <a href="#contributors">Contributors</a> •
  <a href="#licensing">Licensing</a>
</p>

## About

This repository contains the source code of the EU Digital COVID Certificate Verifier App for iOS.

The DGC Verifier Apps are responsible for scanning and verifying DGCs using public keys from national backend servers. Offline verification is supported, if the latest public keys are present in the app's key store. Consequently, once up-to-date keys have been downloaded, the verification works without active internet connection.

**A note on using the apps and released APK files found in this GitHub organization**: The apps are reference implementations that cannot be used in production environments as-is, but rather need to be configured by EU member states to access their national backends.

## Translators 💬

You can help the localization of this project by making contributions to the [/Localization folder](Localization/DGCAVerifier).

## Development

### Prerequisites

- You need a Mac to run Xcode.
- Xcode 12.5+ is used for our builds. The OS requirement is macOS 11.0+.
- To install development apps on physical iPhones, you need an Apple Developer account.
- Service Endpoints:
  - This App talks to the pubkey endpoint: `https://dgca-verifier-service.cfapps.eu10.hana.ondemand.com`,
  - Or anotherone specified as serverURI in `DGCAVerifier/Services/GatewayConnection.swift`.
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

- [ ] TODO: Link to documentation

## Support and feedback

The following channels are available for discussions, feedback, and support requests:

| Type               | Channel                                                                                                                                                                          |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Issues**         | <a href="/../../issues" title="Open Issues"><img src="https://img.shields.io/github/issues/eu-digital-green-certificates/dgca-verifier-app-ios?style=flat"></a>                  |
| **Other requests** | <a href="mailto:opensource@telekom.de" title="Email DGC Team"><img src="https://img.shields.io/badge/email-DGC%20team-green?logo=mail.ru&style=flat-square&logoColor=white"></a> |

## How to contribute

Contribution and feedback is encouraged and always welcome. For more information about how to contribute, the project structure, as well as additional contribution information, see our [Contribution Guidelines](./CONTRIBUTING.md). By participating in this project, you agree to abide by its [Code of Conduct](./CODE_OF_CONDUCT.md) at all times.

## Contributors

Our commitment to open source means that we are enabling -in fact encouraging- all interested parties to contribute and become part of its developer community.

## Licensing

Copyright (C) 2021 T-Systems International GmbH and all other contributors

Licensed under the **Apache License, Version 2.0** (the "License"); you may not use this file except in compliance with the License.

You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the [LICENSE](./LICENSE) for the specific language governing permissions and limitations under the License.
