import SwiftUI
import AVFoundation
import UIKit

struct FaceCaptureView: UIViewControllerRepresentable {
    var userID: String
    var isForVerification: Bool
    var onComplete: (UIImage) -> Void

    func makeUIViewController(context: Context) -> FaceCaptureViewController {
        let controller = FaceCaptureViewController()
        controller.userID = userID
        controller.isForVerification = isForVerification
        controller.onComplete = onComplete
        return controller
    }

    func updateUIViewController(_ uiViewController: FaceCaptureViewController, context: Context) {}
}

class FaceCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var userID: String = ""
    var isForVerification: Bool = true
    var onComplete: ((UIImage) -> Void)?

    private var session = AVCaptureSession()
    private var output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Capture Face", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    private func setupCamera() {
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else {
            print("❌ Camera setup failed.")
            return
        }

        session.addInput(input)
        session.addOutput(output)

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        session.startRunning()
    }

    private func setupUI() {
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 160),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        captureButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
    }

    @objc private func captureImage() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("❌ Failed to process image")
            return
        }

        DispatchQueue.main.async {
            self.onComplete?(image)
            self.dismiss(animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
}
