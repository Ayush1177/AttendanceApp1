import SwiftUI
import AVFoundation
import UIKit

struct TestCameraCaptureView: UIViewControllerRepresentable {
    var onCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> TestCameraViewController {
        let controller = TestCameraViewController()
        controller.onImageCaptured = onCaptured
        return controller
    }

    func updateUIViewController(_ uiViewController: TestCameraViewController, context: Context) {}
}

class TestCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onImageCaptured: ((UIImage) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Capture", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        print("🎥 AVCaptureDevice status:", AVCaptureDevice.authorizationStatus(for: .video).rawValue)

        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        print("📸 Front camera available?", frontCamera != nil)
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        checkPermissionsAndSetupCamera()
    }

    private func checkPermissionsAndSetupCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.showPermissionDeniedMessage()
                    }
                }
            }
        default:
            showPermissionDeniedMessage()
        }
    }

    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input), self.session.canAddOutput(self.output) else {
                print("❌ Failed to set up input/output")
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.output)
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                self.previewLayer?.videoGravity = .resizeAspectFill
                self.previewLayer?.frame = self.view.bounds

                if let layer = self.previewLayer {
                    self.view.layer.insertSublayer(layer, at: 0)
                }

                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                }
            }
        }
    }
    private func setupUI() {
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 120),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    }

    private func showPermissionDeniedMessage() {
        let label = UILabel()
        label.text = "❌ Camera permission denied.\nEnable it in Settings."
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.frame = view.bounds
        view.addSubview(label)
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("❌ Photo capture failed.")
            return
        }

        DispatchQueue.main.async {
            self.onImageCaptured?(image)
            self.dismiss(animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
}
