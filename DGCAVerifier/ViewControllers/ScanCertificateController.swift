/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-app-core-ios
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
//  ScanCertificateController.swift
//
//  Created by Yannick Spreen on 4/8/21.
//
//  https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
//

import UIKit
import SwiftDGC
import Vision
import AVFoundation
import CoreNFC

protocol ScanCertificateDelegate: AnyObject {
  func scanController(_ controller: ScanCertificateController, didScanCertificate certificate: HCert)
  func scanController(_ controller: ScanCertificateController, didFailWithError error: CertificateParsingError)
  func disableBackgroundDetection()
  func enableBackgroundDetection()
}

class ScanCertificateController: UIViewController, DismissControllerDelegate, NFCNDEFReaderSessionDelegate {
  private enum Constants {
    static let userDefaultsCountryKey = "UDCountryKey"
    static let showSettingsSegueID = "showSettingsSegueID"
    static let showCertificateViewer = "showCertificateViewer"
  }

  @IBOutlet fileprivate weak var aNFCButton: UIButton!
  @IBOutlet fileprivate weak var settingsButton: UIButton!
  @IBOutlet fileprivate weak var camView: UIView!
  @IBOutlet fileprivate weak var countryCodeView: UIPickerView!
  @IBOutlet fileprivate weak var countryCodeLabel: UILabel!
 
  weak var delegate: ScanCertificateDelegate?
  private var captureSession: AVCaptureSession?
  private var countryItems: [CountryModel] = []
  
  var downloadedDataHasExpired: Bool {
    return DataCenter.lastFetch.timeIntervalSinceNow < -SharedConstants.expiredDataInterval
  }

  lazy private var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
    guard error == nil else {
      self.showAlert(withTitle: "Barcode Error".localized, message: error?.localizedDescription ?? "Something went wrong.".localized)
      return
    }
    self.processClassification(request)
  }
  
  private var selectedCounty: CountryModel? {
    set {
      do {
        try UserDefaults.standard.setObject(newValue, forKey: Constants.userDefaultsCountryKey)
      } catch {
        DGCLogger.logError(error)
      }
    }
    get {
      do {
        let selected = try UserDefaults.standard.getObject(forKey: Constants.userDefaultsCountryKey,
            castTo: CountryModel.self)
        return selected
      } catch {
        DGCLogger.logError(error)
        return nil
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if #available(iOS 13.0, *) {
      aNFCButton.setBackgroundImage(UIImage(named: "icon_nfc")?.withTintColor(.white), for: .normal)
    } else {
      aNFCButton.setBackgroundImage(UIImage(named: "icon_nfc"), for: .normal)
    }
    
    delegate = self
    countryCodeLabel.text = "Select Country of CertLogic Rule".localized
    let countryList = DataCenter.countryCodes.sorted(by: { $0.name < $1.name })
    setListOfRuleCounties(list: countryList)
    
  #if targetEnvironment(simulator)
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
      self.observationHandler(payloadString: "HC1:6BFA70$90T9WTWGSLKC 4X7923S%CA.48Y+6/AB3XK5F3 026003F3RD6Z*B1JC X8Y50.FK8ZKO/EZKEZ967L6C56..DX%DZJC2/D:+9 QE5$CLPCG/D0.CHY8ITAUIAI3DG8DXFF 8DXEDU3EI3DAWE1Z9CN9IB85T9JPCT3E5JDOA73467463W5-A67:EDOL9WEQDD+Q6TW6FA7C466KCK9E2H9G:6V6BEM6Q$D.UDRYA 96NF6L/5QW6307B$D% D3IA4W5646946%96X47XJC$+D3KC.SCXJCCWENF6OF63W5CA7746WJCT3E0ZA%JCIQEAZAWJC0FD6A5AIA%G7X+AQB9F+ALG7$X85+8+*81IA3H87+8/R8/A8+M986APH9$59/Y9WA627B873 3K9UD5M3JFG.BOO3L-GE828UE0T46/*JSTLE4MEJRX797NEXF5I$2+.LGOJXF24D2WR9 W8WQT:HHJ$7:TKP2RT+J:G4V5GT7E")
    }
  #else
    captureSession = AVCaptureSession()
    checkPermissions()
    setupCameraLiveView()
  #endif
    SquareViewFinder.create(from: self)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    captureSession?.startRunning()
  }
    
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession?.stopRunning()
  }
  
  func userDidDissmiss(_ controller: UIViewController) {
    if downloadedDataHasExpired {
      self.navigationController?.popViewController(animated: false)
    } else {
      captureSession?.startRunning()
    }
  }

  // MARK: Actions
  @IBAction func openSettingsController() {
    captureSession?.stopRunning()
    performSegue(withIdentifier: Constants.showSettingsSegueID, sender: nil)
  }
  
  @IBAction func scanNFCAction() {
    let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
    session.begin()
  }
  
  // MARK: Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showCertificateViewer:
      if let destinationController = segue.destination as? CertificateViewerController,
        let certificate = sender as? HCert {
        destinationController.hCert = certificate
        destinationController.dismissDelegate = self
      }
    case Constants.showSettingsSegueID:
      if let destinationController = (segue.destination as? UINavigationController)?.viewControllers.first as? SettingsController {
        destinationController.dismissDelegate = self
      }
    default:
      break
    }
  }
  
  // MARK: Private
  private func setListOfRuleCounties(list: [CountryModel]) {
    self.countryItems = list
    self.countryCodeView.reloadAllComponents()
    guard self.countryItems.count > 0 else { return }
    
    if let selected = self.selectedCounty,
      let indexOfCountry = self.countryItems.firstIndex(where: {$0.code == selected.code}) {
        countryCodeView.selectRow(indexOfCountry, inComponent: 0, animated: false)
    } else {
      self.selectedCounty = self.countryItems.first
      countryCodeView.selectRow(0, inComponent: 0, animated: false)
    }
  }
  
  private func configurePreviewLayer() {
    guard let captureSession = captureSession else { return }
    
    let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    cameraPreviewLayer.videoGravity = .resizeAspectFill
    cameraPreviewLayer.connection?.videoOrientation = .portrait
    cameraPreviewLayer.frame = view.frame
    camView.layer.insertSublayer(cameraPreviewLayer, at: 0)
  }

  private func showAlert(withTitle title: String, message: String) {
    DispatchQueue.main.async {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
      self.present(alertController, animated: true)
    }
  }

  private func showPermissionsAlert() {
    showAlert(withTitle: "Camera Permissions".localized,
        message: "Please open Settings and grant permission for this app to use your camera.".localized)
  }
  
  // MARK: NFCNDEFReaderSessionDelegate
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    onNFCResult(success: false, message: error.localizedDescription)
  }
  
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    for message in messages {
      for record in message.records {
        var payload : String? = nil;
        if #available(iOS 13.0, *) {
          (payload, _) = record.wellKnownTypeTextPayload()
        } else {
          if (record.typeNameFormat == .nfcWellKnown && record.type.hashValue == 0x54) {
            let definition = record.payload[0]
            let encoding = (((definition & 128) >> 7) == 0) ? String.Encoding.utf8 : String.Encoding.utf16;
            let localeLen = Int(definition & 63)
            payload = String(data: record.payload[localeLen...], encoding: encoding)
          }
        }
        if payload != nil && payload!.prefix(4) == "HC1:" {
          onNFCResult(success: true, message: payload!)
          return
        }
      }
    }
    onNFCResult(success: false, message: "don't found any info")
  }
}

extension ScanCertificateController: ScanCertificateDelegate {
  func scanController(_ controller: ScanCertificateController, didFailWithError error: CertificateParsingError) {
    DispatchQueue.main.async {
      self.showInfoAlert(withTitle: "Barcode Error".localized, message: "Something went wrong.".localized)
    }
  }
  
  func scanController(_ controller: ScanCertificateController, didScanCertificate certificate: HCert) {
    DispatchQueue.main.async {
      self.captureSession?.stopRunning()
      self.performSegue(withIdentifier: Constants.showCertificateViewer, sender: certificate)
    }
  }
  
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }
  
  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }
}

extension ScanCertificateController {
  private func checkPermissions() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      delegate?.disableBackgroundDetection()
      AVCaptureDevice.requestAccess(for: .video) { granted in
        self.delegate?.enableBackgroundDetection()
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
    captureSession?.sessionPreset = .hd1280x720

    let videoDevice = AVCaptureDevice
      .default(.builtInWideAngleCamera, for: .video, position: .back)

    guard let device = videoDevice,
      let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
      captureSession?.canAddInput(videoDeviceInput) == true
    else {
      showAlert(withTitle: "Cannot Find Camera".localized,
          message: "There seems to be a problem with the camera on your device.".localized)
      return
    }

    captureSession?.addInput(videoDeviceInput)

    let captureOutput = AVCaptureVideoDataOutput()
    captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
    captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
    captureSession?.addOutput(captureOutput)
    
    configurePreviewLayer()
  }
  
  func processClassification(_ request: VNRequest) {
    guard let barcodes = request.results else { return }
    
    DispatchQueue.main.async {
      if self.captureSession?.isRunning == true {
        self.camView.layer.sublayers?.removeSubrange(1...)

        if let barcode = barcodes.first {
          let potentialQRCode: VNBarcodeObservation
          if #available(iOS 15, *) {
            guard let potentialCode = barcode as? VNBarcodeObservation,
              [.Aztec, .QR, .DataMatrix].contains(potentialCode.symbology),
              potentialCode.confidence > 0.9
            else { return }
            
            potentialQRCode = potentialCode
          } else {
            guard let potentialCode = barcode as? VNBarcodeObservation,
              [.aztec, .qr, .dataMatrix].contains(potentialCode.symbology),
              potentialCode.confidence > 0.9
            else { return }
            
            potentialQRCode = potentialCode
          }
          DGCLogger.logInfo(potentialQRCode.symbology.rawValue.description)
          self.observationHandler(payloadString: potentialQRCode.payloadStringValue)
        }
      }
    }
  }

  private func observationHandler(payloadString: String?) {
    guard let barcodeString = payloadString, !barcodeString.isEmpty else { return }
    do {
      let countryCode = self.selectedCounty?.code
      let hCert = try HCert(from: barcodeString, ruleCountryCode: countryCode)
      delegate?.scanController(self, didScanCertificate: hCert)
      
    } catch let error as CertificateParsingError {
      DGCLogger.logInfo("Error when validating the certificate? \(barcodeString)")
      delegate?.scanController(self, didFailWithError: error)
    } catch {
      //delegate?.scanController(self, didFailWithError: error)
    }
  }
}

extension ScanCertificateController: AVCaptureVideoDataOutputSampleBufferDelegate {
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    let imageRequestHandler = VNImageRequestHandler( cvPixelBuffer: pixelBuffer, orientation: .right)

    do {
      try imageRequestHandler.perform([detectBarcodeRequest])
    } catch {
      DGCLogger.logError(error)
    }
  }
}

extension ScanCertificateController: UIPickerViewDataSource, UIPickerViewDelegate {
  public func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if countryItems.count == 0 { return 1 }
    return countryItems.count
  }
  
  public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    if countryItems.count == 0 {
      return "Country codes list empty".localized
    } else {
      return countryItems[row].name
    }
  }
  
  public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if countryItems.count > 0 {
      self.selectedCounty = countryItems[row]
    }
  }
}

extension ScanCertificateController {
  func onNFCResult(success: Bool, message: String) {
    DGCLogger.logInfo("NFC: \(message)")
    guard success else { return }
    do {
      let countryCode = self.selectedCounty?.code
      let hCert = try HCert(from: message, ruleCountryCode: countryCode)
      delegate?.scanController(self, didScanCertificate: hCert)
      
    } catch let error as CertificateParsingError {
      DGCLogger.logInfo("Error when validating the certificate from NFC? \(message)")
      delegate?.scanController(self, didFailWithError: error)
    } catch {
      DGCLogger.logError(error)
    }
  }
}
