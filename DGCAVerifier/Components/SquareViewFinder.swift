/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-app-core-ios
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
//  SquareViewFinder.swift
//  
//
//  Created by Yannick Spreen on 4/29/21.
//

import UIKit

class SquareViewFinder {
  public static func newView(from view: UIView? = nil) -> UIView {
    let view = view ?? UIView(frame: .zero)
    view.frame = .zero
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.isUserInteractionEnabled = false
    return view
  }

static func create(from controller: UIViewController) {
    guard let view = controller.view else { return }
      
    let guide = newView()
    let square = newView()
    let imgTopRight = newView(from: UIImageView(image: UIImage(named: "cam_top_right")))
    let imgTopLeft = newView(from: UIImageView(image: UIImage(named: "cam_top_left")))
    let imgBottomRight = newView(from: UIImageView(image: UIImage(named: "cam_bottom_right")))
    let imgBottomLeft = newView(from: UIImageView(image: UIImage(named: "cam_bottom_left")))
    let constraints = [
      guide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      guide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      guide.topAnchor.constraint(equalTo: view.topAnchor),
      guide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.53),
      square.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      square.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
      square.widthAnchor.constraint(equalToConstant: 250),
      square.heightAnchor.constraint(equalToConstant: 250),
      imgTopRight.topAnchor.constraint(equalTo: square.topAnchor),
      imgTopRight.rightAnchor.constraint(equalTo: square.rightAnchor),
      imgBottomRight.bottomAnchor.constraint(equalTo: square.bottomAnchor),
      imgBottomRight.rightAnchor.constraint(equalTo: square.rightAnchor),
      imgBottomLeft.bottomAnchor.constraint(equalTo: square.bottomAnchor),
      imgBottomLeft.leftAnchor.constraint(equalTo: square.leftAnchor),
      imgTopLeft.topAnchor.constraint(equalTo: square.topAnchor),
      imgTopLeft.leftAnchor.constraint(equalTo: square.leftAnchor)
    ]
    for child in [
      guide,
      square,
      imgTopRight,
      imgTopLeft,
      imgBottomRight,
      imgBottomLeft] {
      view.addSubview(child)
    }
    NSLayoutConstraint.activate(constraints)
  }
}
