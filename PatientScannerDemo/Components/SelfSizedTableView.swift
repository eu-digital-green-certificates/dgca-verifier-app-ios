//
//  SelfSizedTableView.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/20/21.
//
//  https://dushyant37.medium.com/swift-4-recipe-self-sizing-table-view-2635ac3df8ab
//

import UIKit

class SelfSizedTableView: UITableView {
  var maxHeight: CGFloat = UIScreen.main.bounds.size.height

  override func reloadData() {
    super.reloadData()
    self.invalidateIntrinsicContentSize()
    self.layoutIfNeeded()
  }

  override var intrinsicContentSize: CGSize {
    let height = min(contentSize.height, maxHeight)
    return CGSize(width: contentSize.width, height: height)
  }
}
