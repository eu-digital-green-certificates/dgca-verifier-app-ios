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
//  LicenseController.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 02.11.2021.
//  
        

import UIKit
import SwiftyJSON
import WebKit
import SwiftDGC

class LicenseController: UIViewController, WKNavigationDelegate {
  @IBOutlet fileprivate weak var packageNameLabel: UILabel!
  @IBOutlet fileprivate weak var licenseWebView: WKWebView!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

  var licenseObject: JSON = []

  override func viewDidLoad() {
    super.viewDidLoad()

    self.packageNameLabel.text = licenseObject["name"].string
    self.licenseWebView.isUserInteractionEnabled = false
    self.licenseWebView.navigationDelegate = self
    if let licenseUrl = licenseObject["licenseUrl"].string {
      loadWebView(licenseUrl)
    }
  }

  func loadWebView(_ packageLink: String) {
    DispatchQueue.main.async {
     let request = URLRequest(url: URL(string: packageLink)!)
      self.licenseWebView?.load(request)
    }
    
    self.activityIndicator.startAnimating()
    self.licenseWebView.navigationDelegate = self
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.activityIndicator.stopAnimating()
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    self.activityIndicator.stopAnimating()
  }
}
