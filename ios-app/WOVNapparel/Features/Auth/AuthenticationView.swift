import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppFlowState
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(red: 244/255, green: 244/255, blue: 245/255).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image("wovn-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .padding(.bottom, 20)
                    
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 24/255, green: 24/255, blue: 27/255))
                    
                    Text(isSignUp ? "Join WOVN to build your spatial identity." : "Sign in to access your spatial identity.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Form Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                }
                .padding(.horizontal, 24)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }
                
                // Email Auth Button
                Button(action: handleEmailAuth) {
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(red: 24/255, green: 24/255, blue: 27/255))
                .cornerRadius(30)
                .padding(.horizontal, 24)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                // Toggle Sign Up / Sign In
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                        errorMessage = ""
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Create one")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 113/255, green: 113/255, blue: 122/255))
                        .underline()
                }
                
                // Dividers
                HStack {
                    VStack { Divider() }
                    Text("OR")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 161/255, green: 161/255, blue: 170/255))
                        .padding(.horizontal, 8)
                    VStack { Divider() }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                
                // OAuth Buttons
                VStack(spacing: 16) {
                    SignInWithAppleButton(.continue) { request in
                        appState.handleAppleSignInRequest(request)
                    } onCompletion: { result in
                        appState.handleAppleSignInCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    
                    Button(action: {
                        appState.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 228/255, green: 228/255, blue: 231/255), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    private func handleEmailAuth() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let uid: String
                if isSignUp {
                    uid = try await FirebaseManager.shared.signUp(email: email, password: password)
                } else {
                    uid = try await FirebaseManager.shared.signIn(email: email, password: password)
                }
                
                DispatchQueue.main.async {
                    appState.isAuthenticated = true
                    appState.fetchUserData(userId: uid)
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
