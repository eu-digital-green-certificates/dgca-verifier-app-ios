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
//    checkPermissions()
//    setupCameraLiveView()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.observationHandler(payloadS: nil)
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
    let payloadS: String? = payloadS ?? "HC1:NCFI.L:9QL$Q9S2CB9SSVYUDU+SOT0I7UTLPI2S6/O0HEWAH7SHMSHCYRVKPXL7MVJ6WCY2MO:UQRQ5NGN/KSXPT8FQI4M+KLDP554CGTKSVLJTZTJB774-3F5RGGU0FU*%FG38HEVZ-RG4ORST6WTK3703T625M/UF3O.$NYQL4KOQZVQ$D.BRFGD62R9 MH16V3O$NK2DB/M9HXHT3T7X9Y4I:X1VEM94DM6LNI9E4TFR6S3K%P6QVJ3 C$Z3H60HA2XN2ZXKQLIW$5I126A4ALRFQD-5Q%668PLIW2VY9O6TNS9Q$DTP57EO2XMY122*SEES:57/ O/SKCO9DWAV6A4$1VH6MYP5:QBXUHB0TI1MKE*3PWJD0%4Y2D0F4YOEMSJ-:2WVR820.+7T948MLW66/3JMOQ8%SNDCO O*KHX$6Y5IDRP*%CYYSF63MICGKPOKUG8O8QT4JAI%1S62ZY8QFJ%:3MRL:839 CXX864K1MH0UCK.NUR4:NQ2S4-L5L+H$SV/G5NK7 7F-8A73D8-S3/HYGNH6CDYDCBM7VRJFOZWT2SFJ*O8YMO8WQHR*9D:/3$01DI7M45TKBU:FG3QSZA4COD8UU3ISPSN:42$3FM1Q.3V26L7NO1KFTRPQM0SIA8S5*52ZDBLBN-N-XF*9WPVQ.7O*LBZFJ3HEY 8W3O6RA2RNVFVU VV4WR6ONAD%GR"
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

extension ScanVC: ChildDismissedDelegate {
  func childDismissed() {
    presentingViewer = nil
  }
}
