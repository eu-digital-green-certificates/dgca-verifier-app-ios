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
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/8/21.
//
//  https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
//

import UIKit
import Vision
import AVFoundation
import DGCVerificationCenter
import DGCCoreLibrary

#if canImport(DCCInspection)
import DCCInspection
#endif

#if canImport(DGCSHInspection)
import DGCSHInspection
#endif

protocol DismissControllerDelegate: AnyObject {
    func userDidDissmis(_ controller: UIViewController)
}

class ScanCertificateController: UIViewController {
    private enum Constants {
        static let showSettingsSegueID = "showSettingsSegueID"
        
        static let showDCCCertificate = "showDCCCertificate"
        static let showICAOCertificate = "showICAOCertificate"
        static let showDIVOCCertificate = "showDIVOCCertificate"
        static let showSHCCredentials = "showSHCCredentials"
    }
    
    @IBOutlet fileprivate weak var aNFCButton: UIButton!
    @IBOutlet fileprivate weak var settingsButton: UIButton!
    @IBOutlet fileprivate weak var verificationButton: UIButton!
    @IBOutlet fileprivate weak var camView: UIView!
    @IBOutlet fileprivate weak var countryCodeView: UIPickerView!
    @IBOutlet fileprivate weak var countryCodeLabel: UILabel!
    @IBOutlet fileprivate weak var headerView: UIView!
    @IBOutlet fileprivate weak var activityHeaderView: UIView!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    
    private var captureSession: AVCaptureSession?
    private var dccCountryItems: [CountryModel] = []
    private var barcodeString: String?
    
    private let verificationCenter = AppManager.shared.verificationCenter
    
    private var expireDataTimer: Timer?
    var downloadedDataHasExpired: Bool {
        return VerificationDataCenter.downloadedDataHasExpired
    }
    
    lazy private var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
        guard error == nil else {
            self.showAlert(withTitle: "Cannot read Barcode".localized, message: error?.localizedDescription ?? "Something went wrong.".localized)
            return
        }
        self.processClassification(request)
    }
    
    private var selectedCounty: CountryModel? {
        set {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(newValue)
                UserDefaults.standard.set(data, forKey: AppManager.userDefaultsCountryKey)
            } catch {
                DGCLogger.logError(error)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: AppManager.userDefaultsCountryKey) {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(CountryModel.self, from: data)
                    return object
                } catch {
                    DGCLogger.logError(error)
                }
            }
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            aNFCButton.setBackgroundImage(UIImage(named: "icon_nfc")?.withTintColor(.white), for: .normal)
        } else {
            aNFCButton.setBackgroundImage(UIImage(named: "icon_nfc"), for: .normal)
        }
        headerView.isHidden = true
        countryCodeView.isHidden = true
        activityHeaderView.isHidden = true
        verificationButton.setTitle("Continue Verification".localized, for: .normal)
        #if targetEnvironment(simulator)
        // do nothing
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
    
    private func showDCCCountryList() {
        headerView.isHidden = false
        countryCodeView.isHidden = false
        verificationButton.isHidden = true
        countryCodeLabel.text = "Select Country of CertLogic Rule".localized
        let countryList = DGCVerificationCenter.countryCodes
        setListOfRuleCounties(list: countryList)
    }
    
    private func hideDCCCountryList() {
        countryCodeView.isHidden = true
        headerView.isHidden = true
    }
    
    // MARK: - Actions
    @objc func reloadExpiredData() {
       if downloadedDataHasExpired {
            captureSession?.stopRunning()
            showAlertReloadDatabase()
       }
    }
    
    @IBAction fileprivate func openSettingsController() {
        captureSession?.stopRunning()
        performSegue(withIdentifier: Constants.showSettingsSegueID, sender: nil)
    }
    
    @IBAction fileprivate func scanNFCAction() {
        let helper = NFCHelper()
        helper.onNFCResult = onNFCResult(success:message:)
        helper.restartSession()
    }
    
    @IBAction fileprivate func verificationAction() {
        hideDCCCountryList()
        if let barcodeString = barcodeString,
           let countryCode = self.selectedCounty?.code {
            self.barcodeString = nil
            
            if let certificate = try? MultiTypeCertificate(from: barcodeString, ruleCountryCode: countryCode) {
                scannerDidScanCertificate(certificate)
            }  else {
                scannerDidFailWithError(error: CertificateParsingError.invalidStructure)
            }
            
        } else {
            self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Please select the country.".localized)
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Constants.showDCCCertificate:
            if let destinationController = segue.destination as? DCCViewerController,
                let certificate = sender as? MultiTypeCertificate {
                destinationController.certificate = certificate
                destinationController.presentationController?.delegate = self
                destinationController.dismissDelegate = self
            }
            
        case Constants.showICAOCertificate:
            break
            // TODO: Add ICAO viewer controller
            
        case Constants.showDIVOCCertificate:
            break
            // TODO: Add ICAO viewer controller
            
        case Constants.showSHCCredentials:
            guard let destinationController = segue.destination as? CardContainerController else { return }
            if let certificate = sender as? MultiTypeCertificate {
                destinationController.certificate = certificate
                destinationController.presentationController?.delegate = self
            }
            destinationController.editMode = false
            destinationController.dismissDelegate = self

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
    
    // MARK: - Private
    private func updateAllStoredData() {
        captureSession?.stopRunning()
        activityHeaderView.isHidden = true
        activityIndicator.startAnimating()
        
        verificationCenter.updateStoredData(appType: .verifier) { [unowned self] result in
            if case let .failure(error) = result {
                DispatchQueue.main.async {
                    DGCLogger.logError(error)
                    self.activityHeaderView.isHidden = true
                    self.activityIndicator.stopAnimating()
                    self.showAlert(withTitle: "Cannot update stored data".localized,
                        message: "Please check the internet connection and try again.".localized)
                    self.captureSession?.startRunning()
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.activityHeaderView.isHidden = true
                    self.showAlert(withTitle: "Stored data is up to date", message: "")
                    self.captureSession?.startRunning()
                }
            }
        }
    }
    
    private func showAlertReloadDatabase() {
        let alert = UIAlertController(title: "Reload databases?".localized,
            message: "The update may take some time.".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Later".localized, style: .default, handler: { _ in
            self.captureSession?.startRunning()
        }))
        
        alert.addAction(UIAlertAction(title: "Reload".localized, style: .default, handler: { [unowned self] (_: UIAlertAction!) in
            self.updateAllStoredData()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func setListOfRuleCounties(list: [CountryModel]) {
        self.dccCountryItems = list
        self.countryCodeView.reloadAllComponents()
        guard self.dccCountryItems.count > 0 else { return }
        
        if let selected = self.selectedCounty,
          let indexOfCountry = self.dccCountryItems.firstIndex(where: {$0.code == selected.code}) {
            countryCodeView.selectRow(indexOfCountry, inComponent: 0, animated: false)
        } else {
            self.selectedCounty = self.dccCountryItems.first
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
        showAlert(withTitle: "Verifier App would like to access the camera".localized,
            message: "Please open the Settings and grant permission for this app to use your camera.".localized)
    }
    
    private func disableBackgroundDetection() {
        SecureBackground.paused = true
    }
    
    private func enableBackgroundDetection() {
        SecureBackground.paused = false
    }
}

// MARK: - Scan of Certificates
extension ScanCertificateController {
    func scannerDidFailWithError(error: Error) {
        DispatchQueue.main.async {
            switch error {
            case CertificateParsingError.invalidStructure:
                self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Cryptographic signature is invalid".localized)
            case CertificateParsingError.unknownFormat:
                self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Unknown certificate type.".localized)
            default:
                self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Unknown barcode format.".localized)
            }
        }
    }
    
    func scannerDidScanCertificate(_ certificate: MultiTypeCertificate) {
        DispatchQueue.main.async { [weak self] in
            self?.captureSession?.stopRunning()
            
            switch certificate.certificateType {
            case .unknown:
                // TODO: Show Alert here
                break
            case .dcc:
                self?.performSegue(withIdentifier: Constants.showDCCCertificate, sender: certificate)
            case .icao:
                self?.performSegue(withIdentifier: Constants.showICAOCertificate, sender: certificate)
            case .divoc:
                self?.performSegue(withIdentifier: Constants.showDIVOCCertificate, sender: certificate)
            case .shc:
                self?.performSegue(withIdentifier: Constants.showSHCCredentials, sender: certificate)
            }
        }
    }
}

// MARK: - AV setup
private extension ScanCertificateController {
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            self.disableBackgroundDetection()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                self.enableBackgroundDetection()
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

    func setupCameraLiveView() {
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
                    self.observationHandler(payload: potentialQRCode.payloadStringValue)
                }
            }
        }
    }
    
    func observationHandler(payload: String?) {
        guard let barcodeString = payload, !barcodeString.isEmpty else { return }
        
        if CertificateApplicant.isApplicableDCCFormat(payload: barcodeString) {
            if self.selectedCounty == nil {
                self.barcodeString = barcodeString
                showDCCCountryList()
                
            } else if self.barcodeString == nil {
                let countryCode = self.selectedCounty?.code
                if let certificate = try? MultiTypeCertificate(from: barcodeString, ruleCountryCode: countryCode) {
                    scannerDidScanCertificate(certificate)
                } else {
                    scannerDidFailWithError(error: CertificateParsingError.invalidStructure)
                }
            }
        
        } else if CertificateApplicant.isApplicableICAOFormat(payload: barcodeString) {
            // TODO: add processing of ICAO format
            
        } else if CertificateApplicant.isApplicableDIVOCFormat(payload: barcodeString) {
            // TODO: add processing of DIVOC format
            
        } else if CertificateApplicant.isApplicableSHCFormat(payload: barcodeString) {
            do {
                let certificate = try MultiTypeCertificate(from: barcodeString)
                scannerDidScanCertificate(certificate)

            } catch CertificateParsingError.kidNotFound(let rawUrl) {
                DGCLogger.logInfo("Error kidNotFound when parse SH card.")
                self.showAlert(title: "Unknown issuer of Smart Card".localized,
                    subtitle: "Do you want to continue to identify the issuer?",
                    actionTitle: "Continue".localized,
                    cancelTitle: "Cancel".localized ) { response in
                    if response {
                        #if canImport(DGCSHInspection)
                        TrustedListLoader.resolveUnknownIssuer(rawUrl) { kidList, result in
                            if let certificate = try? MultiTypeCertificate(from: barcodeString) {
                                self.scannerDidScanCertificate(certificate)
                            } else {
                                DGCLogger.logInfo("Error validating barcodeString: \(barcodeString)")
                                self.scannerDidFailWithError(error: CertificateParsingError.invalidStructure)
                            }
                        }
                        #endif
                        
                    } else { // user cancels
                        DGCLogger.logInfo("User cancelled verifying.")
                    }
                }
                
            } catch let error as CertificateParsingError {
                scannerDidFailWithError(error: error)
            } catch {
                scannerDidFailWithError(error: CertificateParsingError.invalidStructure)
            }
        } else {
            DGCLogger.logInfo("Cannot applicate \(barcodeString) to any available type")
            scannerDidFailWithError(error: CertificateParsingError.unknownFormat)
        }
    }
}

extension ScanCertificateController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
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

// MARK: - Picker delegate
extension ScanCertificateController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dccCountryItems.isEmpty ? 1 : dccCountryItems.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dccCountryItems.isEmpty ? "Country codes list empty".localized : dccCountryItems[row].name
    }
  
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedCounty = dccCountryItems[row]
        verificationButton.isHidden = false
        countryCodeLabel.text = ""
    }
}

// MARK: - NFC Result
extension ScanCertificateController {
    func onNFCResult(success: Bool, message: String) {
        DGCLogger.logInfo("NFC: \(message)")
        guard success, !message.isEmpty else { return }
        if CertificateApplicant.isApplicableDCCFormat(payload: message) {
            if self.selectedCounty == nil {
                self.barcodeString = message
                showDCCCountryList()
                
            } else if self.barcodeString == nil {
                let countryCode = self.selectedCounty?.code
                if let certificate = try? MultiTypeCertificate(from: message, ruleCountryCode: countryCode) {
                    scannerDidScanCertificate(certificate)
                } else {
                    scannerDidFailWithError(error: CertificateParsingError.invalidStructure)
                }
            }
        
        } else if CertificateApplicant.isApplicableICAOFormat(payload: message) {
            // TODO: add processing of ICAO format
            
        } else if CertificateApplicant.isApplicableDIVOCFormat(payload: message) {
            // TODO: add processing of DIVOC format
            
        } else if CertificateApplicant.isApplicableSHCFormat(payload: message) {
            if let certificate = try? MultiTypeCertificate(from: message, ruleCountryCode: nil) {
                scannerDidScanCertificate(certificate)
            } else {
                scannerDidFailWithError(error: CertificateParsingError.invalidStructure)
            }
            
        } else {
            DGCLogger.logInfo("Cannot applicate \(message) to any available type")
            scannerDidFailWithError(error: CertificateParsingError.unknownFormat)
        }
    }
}

// MARK: - Adaptive Presentation Delegate
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
