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
//  SecureBackground.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/27/21.
//  

import UIKit

class SecureBackground {
  static var imageView: UIImageView?
  static var image: UIImage?
  static var paused = false

  static func enable() {
    disable()
    guard !paused, let image = image else { return }
      
    let imageView = UIImageView(image: image)
      UIApplication.shared.windows.first?.addSubview(imageView)
    Self.imageView = imageView
  }

  static func disable() {
    imageView?.removeFromSuperview()
    imageView = nil
  }
}
