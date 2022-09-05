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
//  EUIDController.swift
//  DGCAVerifier
//  
//  Created by Roman Radchuk on 19.08.2022.
//  
        

import UIKit
import SwiftyJSON

class EUIDController: UIViewController {
    
    private enum Constants {
        static let showDCCCertificate = "showDCCCertificate"
    }
    
    @IBOutlet var qrCodeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mock = EUIDRequest()
        qrCodeImageView.image = makeQrCode(mock)
    }

    private func makeQrCode(_ request: EUIDRequest) -> UIImage? {
        guard let encodedData = try? JSONEncoder().encode(request),
              let jsonString = String(data: encodedData, encoding: .utf8) else { return nil }
        if let data = jsonString.data(using: String.Encoding.ascii),
           let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let codeImage = UIImage(ciImage: output)
                return codeImage
            }
        }
        return nil
    }
    
    @IBAction func debugSuccessButtonAction() {
//        self?.performSegue(withIdentifier: Constants.showDCCCertificate, sender: certificate)
    }
    @IBAction func debugFailureButtonAction() {
//        self?.performSegue(withIdentifier: Constants.showDCCCertificate, sender: certificate)
    }
    
}

struct EUIDRequest: Encodable {
    let client_id = "https://client.example.org/post"
    let redirect_uris = ["https://client.example.org/post"]
    let response_types = "vp_token"
    let response_mode = "post"
    let presentation_definition = PresentationDefinition()
    let nonce = "n-0S6_WzA2Mj"
}

struct PresentationDefinition: Encodable {
    
}
