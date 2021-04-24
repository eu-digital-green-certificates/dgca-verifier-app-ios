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
//    checkPermissions()
//    setupCameraLiveView()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.observationHandler(payloadS: nil)
//      let reason = "Log in to your account"
//      var context = LAContext()
//      context.localizedCancelTitle = "Enter Username/Password"
//      context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
//
//          if success {
//
//              // Move to the main thread because a state update triggers UI changes.
//              DispatchQueue.main.async { [unowned self] in
//                  print("loggedin")
//              }
//
//          } else {
//              print(error?.localizedDescription ?? "Failed to authenticate")
//
//              // Fall back to a asking for username and password.
//              // ...
//          }
//      }
    }
  }
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning()
  }

//  let curve: EllipticCurve = .prime256v1
  let name: String = "ECDSA"
  var presentingViewer: CertificateViewerVC?

  // Send the base64URLencoded signature and `header.claims` to BlueECC for verification.
//  func verifySignature(key: Data, signature: Data, for data: Data) -> Bool {
//    do {
//      guard let keyString = String(data: key, encoding: .utf8) else {
//        return false
//      }
//      let r = signature.subdata(in: 0 ..< signature.count/2)
//      let s = signature.subdata(in: signature.count/2 ..< signature.count)
//      let signature = try ECSignature(r: r, s: s)
//      let publicKey = try ECPublicKey(key: keyString)
//      guard publicKey.curve == curve else {
//        return false
//      }
//      return signature.verify(plaintext: data, using: publicKey)
//    }
//    catch {
//      print("Verification failed: \(error)")
//      return false
//    }
//
//  }

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

    captureSession.startRunning()
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
    let payloadS: String? = payloadS ?? "HC1:NCFD:MFY7AP2.532EE3*45+G W84$2J85AUFA3QHN7SXNF$S-4THFSJFIMSKD3799U/LN71G32S0L43XHEIB*983A8RMF1/MMMIS6AQC0QNGU+I.AKYQKBPL%YA-ZVT28J3D+WNNL6SEV%GH$$3NRHO%L8BVLJBL:3F0AKIH3.1U2VS0WZLD75Q52EAENQ-HAYIXTGFH9%ZKA6Q$8A4J67E585MUDPCGCSY3SA7YPCPXCVDL-S0Z.CM6M7%H5POR-ACBI7MT3ZARJ7%S29G596OFMRF-65T6O*M.BJ3DI0W3%:ITBAF 9B1D3SQ$A5LOCTQQZ 40IPR:R3 PUXUN01XD8SJ62MRN$BV502.0HLGS/NXXJ AS.X5QZ2SGTEKLKHB4T8F%S664E02MH2F A.BH9+R7N6N5N.USZXL7DO2AIV2P0XU2.OPI6 C395EPMMGDAD4G-S1DC8ZVJT:3CR3-P8ZVGV8A$DD+*0/MH5+MPDO:L9IJ6MU278C924V:09%1MUQTR2FBL5 6CLODPT304L3GK6OT-7 97U*IO7J:1MB1EU0E.G3C/4P7FXRF-04F9O-9VREIPOSWTFU2W%2F4-B$CSSVNWKAHWJA4NCEU$KLU$GQ6OJ-97UN"
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
//    let payload = CBOR.payload(from: data)
//    presentViewer(for: payload)
//    print(CBOR.payload(from: data)?.toString() ?? "")
//    print(CBOR.header(from: data)?.toString() ?? "")
    presentViewer(for: HCert(from: data))

    GatewayConnection.fetchCert()
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
