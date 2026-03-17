import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var registrationError: String?
    @State private var isLoading = false
    @State private var showFaceCapture = false
    @State private var capturedImage: UIImage?
    @State private var faceCaptured = false
    @State private var userID: String = ""
    
    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty &&
        password == confirmPassword && faceCaptured
    }
    
        var body: some View {
            ZStack {
                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Register")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        
                        Group {
                            TextField("Name", text: $name)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            SecureField("Password", text: $password)
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        
                        Button(faceCaptured ? "Face Captured ✓" : "Capture Face") {
                            showFaceCapture = true
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(faceCaptured ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        if let error = registrationError {
                            Text(error).foregroundColor(.red)
                        }
                        
                        Button("Register") {
                            registerUser()
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isFormValid ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding()
                }
                
            }
            .sheet(isPresented: $showFaceCapture) {
                FaceCaptureView(userID: email, isForVerification: false) { image in
                    self.capturedImage = image
                    self.faceCaptured = true
                }
            }
        }
        
        func registerUser() {
            registrationError = nil
            isLoading = true
            
            guard let face = capturedImage else {
                registrationError = "Face image missing"
                isLoading = false
                return
            }
            
            AuthService.shared.tempRegister(email: email, password: password, name: name, faceImage: face) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let uid):
                        self.userID = uid
                    case .failure(let error):
                        self.registrationError = error.localizedDescription
                    }
                }
            }
        }
    }

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
