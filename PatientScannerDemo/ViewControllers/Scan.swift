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
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.observationHandler(payloadS: nil)
    }
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

  func presentViewer(for certificate: Any?) {
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
    let payloadS: String? = "HC1NCFOXNEG2NBJ5*H:QO-.O /MD064 PJ26UV0 XHLQ9HXKZNEQCSJ591MVBATW$4 S8$96NF6OR5UVBJUB4PJU47326/Z7PCL394Z/MWP4 N66ED6JC:JEG.CZJC0:C6JK:JM$JLAINN6BLHM035L8CCECS.CYMCPOJ5OI9YI:8DRFC%PD*ZLJ9CWVBREJFZM4A7Z/M*+Q.28+VQXCRAHAF27I9QQ60E2KYIJPOJI7J/VJ0 JYSJEZIK7B*IJS7BCLIOCISEBTKBRHSWKJ4:2POJ.GILYJ7GPSVBY4CJZIOMI$MI1VC3TCYR6HCRF46Q96W/6-DP+%PPMC1KJG%HJ*81.7 84-W6I RO5PH6UDUH+/F9PJCQFRVV 8UDJ5QEV2Y8%635OHH0E2:E5VUJZ4 VT3+6ZU598O:E0/ 0VP2IBO6ANG%6UD5RSRO4B6$ES40H/CQ1"
    guard
      let payloadString = payloadS,
      let compressed = try? String(payloadString.dropFirst(3)).fromBase45()
    else { return }

    let data = decompress(compressed)
    let payload = CBOR.payload(from: data)
    presentViewer(for: payload)
    print(CBOR.payload(from: data)?.toString() ?? "")
    print(CBOR.header(from: data)?.toString() ?? "")
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
