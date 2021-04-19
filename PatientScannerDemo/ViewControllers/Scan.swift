//
//  ViewController.swift
//  PatientScannerDemo
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
    checkPermissions()
    setupCameraLiveView()
//    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//      self.observationHandler(payloadS: nil)
//    }
  }
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning()
  }
//  let curve: EllipticCurve = .prime256v1
  let name: String = "ECDSA"

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

  func presentViewer(for certificate: HCert) {
    let fpc = FloatingPanelController()
    guard
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    fpc.set(contentViewController: viewer)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    viewer.hCert = certificate

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
//    let payloadS: String? = "HC1:NCFI.LDVNOJ2J52O/SCFR078MG4:T7WNDXC5$OS9/NQ FD*7L$O:XJ345Y13WIRJXRE7RAYOY1UGZJR$1VAWKCI:248D1P%3CQSP7DZ554GVY55:35QOGVERIS2NBA8Y9YTKW/UD4O$02E$0N6DF:1P:MDXO6$V4:EA6GCMTH0DHJTPOEKYTGBND0GG7M76E$*LHO7:W1V.84QM-0JBQ2FAV7X9R-1:X1XLUI8QF2A1$ID$PGFT+JN*UROVD66HD8F4O03F4L25K/NT89*KMX*8RCH7HDI.BZ-OOC68PLIW2Q1U2 PWHJ$OB RJ BGO/CAA6/DP4IOADM+ZO4PSNTLI+Q EQT*6HN67WP.0W19Q620.C0W-6FJV8G34JH09B4FPTU0PWK2JSSXA410:8KUA6RNLW66/3JZADZCM/13:B6LG40+ERQCELE0R9J477G7+830JE3+NB:56URMXA2K4QP0N8AK%0ICW4*A7ZHCQM*G4B2Q$R8%H659U%D9JBVDB1J8VW7U77IDNG2TKH.5-RU5Y5 WBD-EL8NDWDT%GD$2-RLJGRTVD 8M09BK*2-1E6M9H 5RRK5KOM7PI:SLUH026C 8MOL9/J56J40RG/02481972OFQRI:SFGMM:VUYIH.ZJ+7S5+FJ35*-JE7UE4Q1JMQ%FXVF8KN$7TKUJC2D5.0NAMX53K%V7$R9+QE.NA+I1LQ"
    guard
      let payloadString = payloadS,
      let compressed = try? String(payloadString.dropFirst(4)).fromBase45()
    else { return }

    let data = decompress(compressed)
//    let payload = CBOR.payload(from: data)
//    presentViewer(for: payload)
//    print(CBOR.payload(from: data)?.toString() ?? "")
//    print(CBOR.header(from: data)?.toString() ?? "")
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
