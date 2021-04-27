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
//  ViewController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/8/21.
//
//  https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
//

import UIKit
import Vision
import AVFoundation
import SwiftCBOR
import FloatingPanel
import LocalAuthentication


class ScanVC: UIViewController {
  var captureSession = AVCaptureSession()

  lazy var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
    guard error == nil else {
      self.showAlert(withTitle: "Barcode error", message: error?.localizedDescription ?? "error")
      return
    }
    self.processClassification(request)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    #if targetEnvironment(simulator)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.observationHandler(payloadS: "HC1:NCFOXNYTS3DH$YO:CQSU40 H 804 2FI15B3LR5OGILG9N:5-RII9DL-VAD65D6 NI4EFFZSE+S.SSH2HGUS XKVD9HB58QHVM6IQ17XH0S9S-JX%EI$HGL24EGYJ2SKISE02UQHPMYO9MN9JUHLKH.O93UQFJ6GL28LHXOAYJAPRAAUICO10W59UE1YHU-H4PIUF2VSJGV4J4LV/AYVG2$436D$X40YC2ATNS4Y6TKR2*G5C%CO8TJV4423 L0VV2 73-E3ND3DAJ-432$4U1JS.S./0LWTKD33236J3TA3E-4%:K7-SN2H N37J3JFTULJ5CBP:2C 2+*4HTC/2DBAJDAJCNB-43GV4MCTKD08DJHSI PISVDGZK4EC8.SX1LC8C8DJOMI$MI-N09*0245$UH8QIBD2GMJCKH9AO2R7./HBR6$LE KMDGKRFRSGHQED10H% 0R%0D 8YIPFHL:OTEGJUY25$0P/HX$4T0H//CI+CF/8-0LO1PX$4D4TVZ0D-4VZ0S1LZ0L:M623Q$B65VCNAIO38ZIIT-ROGV86O*$2/6PSQHV-P TN3H38EU2VME.3F$MM3WYC3A1N%IFBZV3P6$A9X81M:L-5TTPNFIVD6KL/O63UX0O7V9BYEB:IB BUAA9JM:ATN.AR81Y4GP21CPVY6P:KPG:LNLL%70/6MRVMT0LV0E7*EVLS2UIU6V2M3%26%Q3J*H:5L-28SXRWUH$LCQ/S3QTY5NG.8C5MN$V4-BXJMF5RG3U6-1RDVRWNY$3/ZB3MOQDWC*08M0AV5*/0QX4B-EF0MGH5X1FYHRGX8:+RY/EI%BQ95TC5*DW/ESR4S0:1ZF59*5GK1-OH4Z6-6FUOTN*H$38IPR4GT1$OE07B*SWKN*HF83N MO.CFOW3R%GB28Z$UOH7DROI9BW/CXPS0.PS USQE:LAVZP320%R902")
    }
    #else
    checkPermissions()
    setupCameraLiveView()
    #endif
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    captureSession.startRunning()
  }

  var presentingViewer: CertificateViewerVC?
  func presentViewer(for certificate: HCert?) {
    guard
      presentingViewer == nil,
      let certificate = certificate,
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    let fpc = FloatingPanelController()
    fpc.set(contentViewController: viewer)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    viewer.hCert = certificate
    viewer.childDismissedDelegate = self
    presentingViewer = viewer

    present(fpc, animated: true, completion: nil)
  }
}


extension ScanVC {
  private func checkPermissions() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [self] granted in
        if !granted {
          self.showPermissionsAlert()
        }
      }
    case .denied, .restricted:
      showPermissionsAlert()
    default:
      return
    }
  }

  private func setupCameraLiveView() {
    captureSession.sessionPreset = .hd1280x720

    let videoDevice = AVCaptureDevice
      .default(.builtInWideAngleCamera, for: .video, position: .back)

    guard
      let device = videoDevice,
      let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
      captureSession.canAddInput(videoDeviceInput) else {
      showAlert(
        withTitle: "Cannot Find Camera",
        message: "There seems to be a problem with the camera on your device.")
      return
    }

    captureSession.addInput(videoDeviceInput)

    let captureOutput = AVCaptureVideoDataOutput()
    captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
    captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
    captureSession.addOutput(captureOutput)

    configurePreviewLayer()
  }

  func processClassification(_ request: VNRequest) {
    guard let barcodes = request.results else { return }
    DispatchQueue.main.async { [self] in
      if captureSession.isRunning {
        view.layer.sublayers?.removeSubrange(1...)

        for barcode in barcodes {
          let _ = barcode
          guard
            let potentialQRCode = barcode as? VNBarcodeObservation,
            [.Aztec, .QR, .DataMatrix].contains(potentialQRCode.symbology),
            potentialQRCode.confidence > 0.9
          else { return }

          print(potentialQRCode.symbology)
          observationHandler(payloadS: potentialQRCode.payloadStringValue)
        }
      }
    }
  }

  func observationHandler(payloadS: String?) {
    guard
      var payloadString = payloadS
    else {
      return
    }

    for prefix in HCert.supportedPrefixes {
      if payloadString.starts(with: prefix) {
        payloadString = String(payloadString.dropFirst(prefix.count))
      }
    }

    guard
      let compressed = try? payloadString.fromBase45()
    else {
      return
    }

    let data = decompress(compressed)
    presentViewer(for: HCert(from: data))
  }

}


extension ScanVC: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    let imageRequestHandler = VNImageRequestHandler(
      cvPixelBuffer: pixelBuffer,
      orientation: .right
    )

    do {
      try imageRequestHandler.perform([detectBarcodeRequest])
    } catch {
      print(error)
    }
  }
}


extension ScanVC {
  private func configurePreviewLayer() {
    let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    cameraPreviewLayer.videoGravity = .resizeAspectFill
    cameraPreviewLayer.connection?.videoOrientation = .portrait
    cameraPreviewLayer.frame = view.frame
    view.layer.insertSublayer(cameraPreviewLayer, at: 0)
  }

  private func showAlert(withTitle title: String, message: String) {
    DispatchQueue.main.async {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(alertController, animated: true)
    }
  }

  private func showPermissionsAlert() {
    showAlert(
      withTitle: "Camera Permissions",
      message: "Please open Settings and grant permission for this app to use your camera."
    )
  }
}

extension ScanVC: ChildDismissedDelegate {
  func childDismissed() {
    presentingViewer = nil
  }
}
