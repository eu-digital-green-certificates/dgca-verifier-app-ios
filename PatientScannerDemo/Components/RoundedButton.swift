//
//  RoundedButton.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import UIKit

@IBDesignable
class RoundedButton: UIButton {
  @IBInspectable var radius: CGFloat = 6.0 { didSet(v) { initialize() } }
  @IBInspectable var padding: CGFloat = 4.0 { didSet(v) { initialize() } }

  override init(frame: CGRect) {
    super.init(frame: frame)

    initialize()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    initialize()
  }

  func initialize() {
    layer.cornerRadius = radius
    contentEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
  }
}
