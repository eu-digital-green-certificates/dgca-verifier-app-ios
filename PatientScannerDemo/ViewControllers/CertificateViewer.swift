//
//  CertificateViewer.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import UIKit
import FloatingPanel

let DISMISS_TIMEOUT = 15.0

class CertificateViewerVC: UIViewController {
  @IBOutlet var nameLabel: UILabel!
  @IBOutlet var loadingBackground: UIView!
  @IBOutlet var loadingBackgroundTrailing: NSLayoutConstraint!

  var hCert: HCert! {
    didSet {
      self.draw()
    }
  }

  var childDismissedDelegate: ChildDismissedDelegate?

  func draw() {
    nameLabel.text = hCert.fullName
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    return
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    loadingBackground.layer.zPosition = -1
    loadingBackgroundTrailing.priority = .init(200)
    UIView.animate(withDuration: DISMISS_TIMEOUT, delay: 0, options: .curveLinear) { [weak self] in
      self?.view.layoutIfNeeded()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + DISMISS_TIMEOUT) { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }

    return
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    childDismissedDelegate?.childDismissed()
  }

  @IBAction
  func closeButton() {
    dismiss(animated: true, completion: nil)
  }
}
