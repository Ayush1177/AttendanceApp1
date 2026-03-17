import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var loginError: String?
    @State private var isLoading = false
    @AppStorage("user_id") private var userID: String = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Login")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    if let loginError = loginError {
                        Text(loginError)
                            .foregroundColor(.red)
                    }

                    Button("Login") {
                        loginUser()
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(
                        isLoading ? ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white)) : nil
                    )

                    Spacer()

                    NavigationLink("Don't have an account? Register", destination: RegisterView())
                        .foregroundColor(.white)
                        .padding(.top)
                }
                .padding()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                DashboardView()
            }
        }
    }

    func loginUser() {
        loginError = nil
        isLoading = true

        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let uid):
                    self.userID = uid
                    self.isLoggedIn = true
                case .failure(let error):
                    self.loginError = error.localizedDescription
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
