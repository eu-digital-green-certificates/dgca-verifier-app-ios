//
//  HomeViewController.swift
//  dgp-whitelabel-ios
//
//

import UIKit
import Vision
import AVFoundation

protocol CameraCoordinator: Coordinator {
    func showVerificationFor(payloadString: String)
    func dismissCamera()
}

class CameraViewController: UIViewController {
    weak var coordinator: CameraCoordinator?
    private var captureSession = AVCaptureSession()

    @IBOutlet weak var cameraView: UIView!

    private let allowedCodes: [VNBarcodeSymbology] = [.Aztec, .QR, .DataMatrix]
    private let scanConfidence: VNConfidence = 0.9

    // MARK: - Init
    init(coordinator: CameraCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: "CameraViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Controller
    override func viewDidLoad() {
        super.viewDidLoad()

        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.found(payload: mockQRCode)
        }
        #else
        checkPermissions()
        setupCameraView()
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

    @IBAction func back(_ sender: Any) {
        coordinator?.dismissCamera()
    }

    private func found(payload: String) {
        coordinator?.showVerificationFor(payloadString: payload)
    }

    // MARK: - Permissions

    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [self] granted in
                if !granted {
                    self.showPermissionsAlert()
                }
            }
        case .denied, .restricted:
            self.showPermissionsAlert()
        default:
            return
        }
    }
    private func showPermissionsAlert() {
        self.showAlert(withTitle: "alert.cameraPermissions.title".localized,
                       message: "alert.cameraPermissions.message".localized)
    }

    // MARK: - Setup

    private func setupCameraView() {
        captureSession.sessionPreset = .hd1280x720

        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

        guard let device = videoDevice, let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(videoDeviceInput) else {
            self.showAlert(withTitle: "alert.nocamera.title".localized, message: "alert.nocamera.message".localized)
            return
        }

        captureSession.addInput(videoDeviceInput)

        // Camera output.
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        captureSession.addOutput(captureOutput)

        // Camera preview layer
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewLayer.frame = view.frame
        cameraView.layer.insertSublayer(cameraPreviewLayer, at: 0)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        let detectBarcodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
            guard error == nil else {
                self?.showAlert(withTitle: "alert.barcodeError.title".localized, message: error?.localizedDescription ?? "error")
                return
            }

            self?.processBarcodesRequest(request)
        }

        do {
            try imageRequestHandler.perform([detectBarcodeRequest])
        } catch {
            print(error)
        }
    }

    func processBarcodesRequest(_ request: VNRequest) {
        guard let barcodes = request.results else { return }

        DispatchQueue.main.async { [self] in
            cameraView.layer.sublayers?.removeSubrange(1...)

            if captureSession.isRunning {
                for barcode in barcodes {
                    guard let potentialQRCode = barcode as? VNBarcodeObservation,
                          allowedCodes.contains(potentialQRCode.symbology),
                          potentialQRCode.confidence > scanConfidence else { return }

                    found(payload: potentialQRCode.payloadStringValue ?? "")
                }
            }
        }
    }
}
