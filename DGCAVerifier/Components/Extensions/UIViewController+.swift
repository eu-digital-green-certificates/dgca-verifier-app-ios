//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-wallet-app-ios
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
//  UIViewController+.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 08.07.2021.
//  
        

import UIKit

extension UIViewController {
    @available(iOS 13.0, *)
    var sceneDelegate: SceneDelegate? {
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let delegate = windowScene.delegate as? SceneDelegate else { return nil }
      return delegate
    }
}

extension UIViewController {
    func showInputDialog(
      title: String? = nil,
      subtitle: String? = nil,
      actionTitle: String? = "OK".localized,
      cancelTitle: String? = "Cancel".localized,
      inputPlaceholder: String? = nil,
      inputKeyboardType: UIKeyboardType = UIKeyboardType.default,
      capitalization: UITextAutocapitalizationType? = nil,
      handler: ((_ text: String?) -> Void)? = nil) {
      let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
      alert.addTextField { (textField: UITextField) in
          textField.placeholder = inputPlaceholder
          textField.keyboardType = inputKeyboardType
          if let cap = capitalization {
              textField.autocapitalizationType = cap
          }
      }
      
      alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
          guard let textField = alert.textFields?.first else {
              handler?(nil)
              return
          }
          handler?(textField.text)
        })
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            handler?(nil)
        })
        present(alert, animated: true, completion: nil)
    }

    func showAlert(
        title: String? = nil,
        subtitle: String? = nil,
        actionTitle: String? = "OK".localized,
        cancelTitle: String? = nil,
        handler: ((Bool) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
            handler?(true)
        })
        if let cancelTitle = cancelTitle {
          alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
              handler?(false)
          })
        }
        present(alert, animated: true, completion: nil)
    }

    func showInfoAlert(withTitle title: String, message: String) {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(alertController, animated: true)
    }
}
