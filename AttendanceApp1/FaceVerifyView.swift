import SwiftUI

struct FaceVerifyView: View {
    let userID: String
    @State private var verificationResult = ""
    @State private var showCamera = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Face Verification")
                .font(.largeTitle)
                .padding(.bottom, 20)

            if !verificationResult.isEmpty {
                Text(verificationResult)
                    .foregroundColor(verificationResult.contains("✅") ? .green : .red)
                    .font(.title2)
            }

            Button(action: {
                showCamera = true
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Scan Face")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(10)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showCamera) {
            FaceCaptureView(userID: userID, isForVerification: true) { image in
                isLoading = true
                verifyCapturedFace(image: image)
            }
        }
    }

    private func verifyCapturedFace(image: UIImage) {
        print("1. Starting face verification process") // Debug
        isLoading = true
        
        print("2. Calling liveness check") // Debug
        AuthService.shared.checkLiveness(image: image) { livenessResult in
            print("3. Received liveness result") // Debug
            DispatchQueue.main.async {
                switch livenessResult {
                case .success(let isLive):
                    print("4. Liveness result: \(isLive ? "Live" : "Not live")") // Debug
                    if isLive {
                        print("5. Proceeding with face verification") // Debug
                        AuthService.shared.verifyFace(userID: userID, image: image) { result in
                            // ... existing code
                        }
                    } else {
                        print("5. Liveness check failed") // Debug
                        isLoading = false
                        verificationResult = "❌ Liveness check failed. Try again with a real face."
                    }

                case .failure(let error):
                    print("5. Liveness check error: \(error.localizedDescription)") // Debug
                    isLoading = false
                    verificationResult = "⚠️ Liveness error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FaceVerifyView_Previews: PreviewProvider {
    static var previews: some View {
        FaceVerifyView(userID: "demo123")
    }
}
