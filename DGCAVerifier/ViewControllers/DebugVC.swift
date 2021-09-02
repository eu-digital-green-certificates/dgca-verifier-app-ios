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
//  DebugVC.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 02.09.2021.
//  
        
let debugKey = "UDDebugSwitchConstants"

import UIKit

class DebugVC: UIViewController {

  @IBOutlet weak var debugSwitcher: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

     
      //debugSwitcher.isOn = UserDefaults.standard.bool(forKey: debugKey)
      // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
  
  @IBAction func debugSwitchAction(_ sender: Any) {
    UserDefaults.standard.set(debugSwitcher.isOn, forKey: debugKey)
    UserDefaults.standard.synchronize()
  }


}
