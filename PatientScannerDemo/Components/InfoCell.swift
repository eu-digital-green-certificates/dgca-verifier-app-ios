//
//  InfoCell.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/20/21.
//

import UIKit

class InfoCell: UITableViewCell {
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!

  func draw(_ info: InfoSection) {
    headerLabel?.text = info.header
    contentLabel?.text = info.content
  }
}
