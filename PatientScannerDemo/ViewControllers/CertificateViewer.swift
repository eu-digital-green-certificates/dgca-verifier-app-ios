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
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var loadingBackground: UIView!
  @IBOutlet weak var loadingBackgroundTrailing: NSLayoutConstraint!
  @IBOutlet weak var typeSegments: UISegmentedControl!
  @IBOutlet weak var infoTable: UITableView!

  var hCert: HCert! {
    didSet {
      self.draw()
    }
  }

  var childDismissedDelegate: ChildDismissedDelegate?

  func draw() {
    nameLabel.text = hCert.fullName
    infoTable.reloadData()
    typeSegments.selectedSegmentIndex = [
      HCertType.test,
      HCertType.vaccineOne,
      HCertType.vaccineTwo,
      HCertType.recovery
    ].firstIndex(of: hCert.type) ?? 0
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // selected option color
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
    // color of other options
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)

    infoTable.dataSource = self

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

extension CertificateViewerVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return hCert.info.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let base = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
    guard let cell = base as? InfoCell else {
      return base
    }
    cell.draw(hCert.info[indexPath.row])
    return cell
  }
}
