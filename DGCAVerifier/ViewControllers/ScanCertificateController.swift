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

protocol DismissControllerDelegate: AnyObject {
  func userDidDissmis(_ controller: UIViewController)
}

protocol ScanCertificateDelegate: AnyObject {
  func scanController(_ controller: ScanCertificateController, didScanCertificate certificate: HCert)
  func scanController(_ controller: ScanCertificateController, didFailWithError error: CertificateParsingError)
  func disableBackgroundDetection()
  func enableBackgroundDetection()
}

class ScanCertificateController: UIViewController {
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
    
    lazy var indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    lazy var progressView: UIProgressView = UIProgressView(progressViewStyle: .`default`)

    lazy var activityAlert: UIAlertController = {
        let controller = UIAlertController(title: "Loading data", message: "\n\n\n", preferredStyle: .alert)
        controller.view.addSubview(progressView)
        progressView.setProgress(0.0, animated: false)
        return controller
    }()

    weak var delegate: ScanCertificateDelegate?
    private var captureSession: AVCaptureSession?
    private var countryItems: [CountryModel] = []
    
    private var expireDataTimer: Timer?
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

    deinit {
        let center = NotificationCenter.default
        center.removeObserver(self)
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
        
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name("StartLoadingNotificationName"), object: nil, queue: .main) { notification in
            self.activityAlert.dismiss(animated: true, completion: nil)
            self.present(self.activityAlert, animated: true) {
                //self.indicator.center = CGPoint(x: self.activityAlert.view.frame.size.width/2, y: 80)
                self.progressView.center = CGPoint(x: self.activityAlert.view.frame.size.width/2, y: 80)
            }
            
        }
        center.addObserver(forName: Notification.Name("StopLoadingNotificationName"), object: nil, queue: .main) { notification in
            self.activityAlert.dismiss(animated: true, completion: nil)
            self.progressView.setProgress(0.0, animated: false)
        }

        center.addObserver(forName: Notification.Name("LoadingRevocationsNotificationName"), object: nil, queue: .main) { notification in
            let strMessage = notification.userInfo?["name"] as? String ?? "Loading Database"
            self.activityAlert.title = strMessage
            let percentage = notification.userInfo?["progress" ] as? Float ?? 0.0
            self.progressView.setProgress(percentage, animated: true)
        }

        #if targetEnvironment(simulator)
        #else
          captureSession = AVCaptureSession()
          checkPermissions()
          setupCameraLiveView()
        #endif
          SquareViewFinder.create(from: self)
          expireDataTimer = Timer.scheduledTimer(timeInterval: 1800, target: self, selector: #selector(reloadExpiredData),
              userInfo: nil, repeats: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    captureSession?.startRunning()
  }
    
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession?.stopRunning()
  }
  
  // MARK: Actions
  @objc func reloadExpiredData() {
     if downloadedDataHasExpired {
          captureSession?.stopRunning()
          showAlertReloadDatabase()
     }
  }
  
  @IBAction func openSettingsController() {
    captureSession?.stopRunning()
    performSegue(withIdentifier: Constants.showSettingsSegueID, sender: nil)
  }
  
    @IBAction func scanNFCAction() {
      let helper = NFCHelper()
      helper.onNFCResult = onNFCResult(success:message:)
      helper.restartSession()
    }

  // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Constants.showCertificateViewer:
            if let destinationController = segue.destination as? CertificateViewerController,
               let certificate = sender as? HCert {
                destinationController.hCert = certificate
                destinationController.presentationController?.delegate = self
                destinationController.dismissDelegate = self
            }
        case Constants.showSettingsSegueID:
            if let navController = segue.destination as? UINavigationController,
                let destinationController = navController.viewControllers.last as? SettingsController {
                navController.presentationController?.delegate = self
                destinationController.dismissDelegate = self
            }
        default:
          break
        }
    }

    // MARK: Private
    
    func showAlertReloadDatabase() {
        let alert = UIAlertController(title: "Reload databases?".localized, message: "The update may take some time.".localized, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Later".localized, style: .default, handler: { _ in
            self.captureSession?.startRunning()
        }))
        
        alert.addAction(UIAlertAction(title: "Reload".localized, style: .default, handler: { [unowned self] (_: UIAlertAction!) in
            self.captureSession?.stopRunning()
            DataCenter.reloadStorageData(completion: { result in
                DispatchQueue.main.async {
                    self.captureSession?.startRunning()
                }
           })
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
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
    self.selectedCounty = countryItems[row]
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

extension ScanCertificateController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss( _ presentationController: UIPresentationController) {
      captureSession?.startRunning()
    }
}

extension ScanCertificateController:  DismissControllerDelegate {
    public func userDidDissmis(_ controller: UIViewController) {
      captureSession?.startRunning()
    }
}
