//
//  AuthenticationView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 2/3/25.
//


import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var env: AppDependencies
    @Binding var isPresented: Bool
    
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var isAuthenticating: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
                
                Text("Autenticazione Richiesta")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Inserisci la password per visualizzare i dati di vendita")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            // Password field
            VStack(spacing: 6) {
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if showError {
                    Text("Password non valida. Riprova.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    authenticate()
                } label: {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    } else {
                        Text("Accedi")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .disabled(password.isEmpty || isAuthenticating)
                
                Button {
                    isPresented = false
                } label: {
                    Text("Annulla")
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .padding(.horizontal, 24)
    }
    
    private func authenticate() {
        isAuthenticating = true
        showError = false
        
        // Simulate a slight delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let salesStore = env.salesStore
            if salesStore.authenticate(password: password) {
                // Authentication succeeded
                isAuthenticating = false
                isPresented = false
            } else {
                // Authentication failed
                isAuthenticating = false
                showError = true
                password = ""
            }
        }
    }
}

#Preview {
    AuthenticationView(isPresented: .constant(true))
        .environmentObject(AppDependencies())
}
