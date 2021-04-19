//
//  FullFloatingPanelLayout.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import FloatingPanel

class FullFloatingPanelLayout: FloatingPanelLayout {
  var position: FloatingPanelPosition = .bottom

  var initialState: FloatingPanelState = .full

  var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
    let top = FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea)
    return [
      .full: top,
    ]
  }
}
